"""
E09_ValidationRepair.py
Experiment 9: Validation Feedback and Self-Repair Generation
Purpose  : Generate → offline validate → feed errors back → LLM self-repairs → re-evaluate.
           Measures improvement delta between initial and repaired versions.
Samples  : 300
Model    : LLaMA 3.3 70B via Together AI
"""

from __future__ import annotations
import json
import os
import re
import time
from tqdm import tqdm

from config import RESULTS_DIR, OUTPUT_DIR
from dataset_loader import build_test_prompts, load_modules
from llm_client import generate, SYSTEM_TERRAFORM
from evaluator import (
    evaluate, aggregate_results, compute_final_score,
    check_hcl_syntax, check_format,
    count_security_issues, count_hardcoded_secrets,
    check_resource_coverage, check_dependency_correctness,
)

EXPERIMENT_ID   = "E09"
EXPERIMENT_NAME = "Validation Feedback Repair"
RESULTS_FILE    = os.path.join(RESULTS_DIR, "E09_ValidationRepair_results.json")
OUTPUT_CODE_DIR = os.path.join(OUTPUT_DIR,  "E09_ValidationRepair_generated")
os.makedirs(OUTPUT_CODE_DIR, exist_ok=True)

REPAIR_SYSTEM_PROMPT = (
    "You are an expert Terraform Infrastructure-as-Code engineer specialising in "
    "debugging and repairing Terraform HCL code. "
    "You will receive the original Terraform code and a structured list of validation "
    "errors, formatting issues, and security warnings. "
    "Fix ALL listed issues. Keep all existing resources – only fix the problems listed. "
    "Return only the corrected, complete Terraform HCL code. No explanations."
)


# ─── Feedback generator ───────────────────────────────────────────────────────

def _generate_feedback(code: str, prompt: str) -> list[str]:
    feedback = []

    if not check_hcl_syntax(code):
        feedback.append(
            "ERROR [HCL Syntax]: Invalid HCL structure detected. "
            "Check for unbalanced braces {}, missing closing brackets, or invalid block syntax."
        )

    if not check_format(code):
        feedback.append(
            "WARNING [Format]: Code does not meet Terraform formatting standards. "
            "Use 2-space indentation and consistent spacing around '=' assignments."
        )

    sec = count_security_issues(code)
    if sec > 0:
        issues = []
        if re.search(r'cidr_blocks\s*=\s*\[?"0\.0\.0\.0/0"', code):
            issues.append("open ingress 0.0.0.0/0 detected")
        if re.search(r'from_port\s*=\s*22.*?cidr_blocks', code, re.DOTALL):
            issues.append("SSH port 22 open to unrestricted CIDR")
        if re.search(r'acl\s*=\s*"public-read"', code):
            issues.append("bucket ACL set to public-read")
        if re.search(r'publicly_accessible\s*=\s*true', code):
            issues.append("database set to publicly_accessible = true")
        if re.search(r'source_ranges\s*=\s*\[?"0\.0\.0\.0/0"', code):
            issues.append("GCP firewall open to 0.0.0.0/0")
        if re.search(r'enable_https_traffic_only\s*=\s*false', code):
            issues.append("HTTPS not enforced on storage account")
        feedback.append(
            f"SECURITY [{sec} issue(s)]: {', '.join(issues)}. "
            "Fix all security issues – restrict CIDRs, remove public access, enforce HTTPS."
        )

    secrets = count_hardcoded_secrets(code)
    if secrets > 0:
        feedback.append(
            f"SECURITY [{secrets} secret(s)]: Hardcoded credential(s) detected "
            "(password / key / token). Replace ALL hardcoded values with Terraform "
            "variable references (var.xxx)."
        )

    dep_score = check_dependency_correctness(code)
    if dep_score < 0.6:
        feedback.append(
            "ERROR [Dependencies]: Resources appear to use hardcoded IDs instead of "
            "Terraform references. Replace all hardcoded subnet IDs, security group IDs, "
            "and resource IDs with references like resource_type.resource_name.attribute."
        )

    coverage = check_resource_coverage(code, prompt)
    if coverage < 0.7:
        feedback.append(
            f"WARNING [Coverage {coverage:.0%}]: The generated code is missing one or more "
            "resources mentioned in the prompt. Review the requirement and add all missing resources."
        )

    if not re.search(r'\bvar\.', code):
        feedback.append(
            "BEST PRACTICE [Variables]: No Terraform variables used. "
            "Declare variable blocks for all configurable and sensitive values."
        )

    if not re.search(r'\boutput\s+"', code):
        feedback.append(
            "BEST PRACTICE [Outputs]: No output blocks declared. "
            "Add output blocks for key resource attributes (IDs, endpoints, ARNs)."
        )

    if not re.search(r'\btags\s*=\s*\{|\blabels\s*=\s*\{', code):
        feedback.append(
            "BEST PRACTICE [Tags/Labels]: No tags or labels found. "
            "Add tags/labels to all resources for identification and cost management."
        )

    return feedback


def _initial_prompt(prompt_text: str) -> str:
    return (
        "Generate complete Terraform HCL code for the following infrastructure requirement:\n\n"
        f"{prompt_text}\n\n"
        "Output only valid Terraform HCL code. No explanations."
    )


def _repair_prompt(original_code: str, feedback: list[str], prompt_text: str) -> str:
    fb_block = "\n".join(f"  [{i+1}] {fb}" for i, fb in enumerate(feedback))
    return (
        "The following Terraform HCL code requires correction:\n\n"
        f"--- Original Code ---\n{original_code}\n\n"
        f"--- Validation Issues ---\n{fb_block}\n\n"
        f"--- Original Requirement ---\n{prompt_text}\n\n"
        "Fix ALL listed issues. Keep all existing resources intact. "
        "Return the complete corrected Terraform HCL code only."
    )


def run():
    print(f"\n{'='*60}")
    print(f"  {EXPERIMENT_ID}: {EXPERIMENT_NAME}  |  300 samples")
    print(f"{'='*60}\n")

    prompts = build_test_prompts()
    modules = load_modules()
    reference_corpus = [
        m["content"] for mods in modules.values() for m in mods[:50]
    ]

    all_results = []

    for sample in tqdm(prompts, desc=EXPERIMENT_ID):

        # Step 1 – Initial generation
        try:
            initial_code = generate(SYSTEM_TERRAFORM, _initial_prompt(sample["prompt"]))
        except Exception as e:
            print(f"  [ERROR initial] {sample['id']}: {e}")
            initial_code = ""

        initial_metrics = evaluate(
            code=initial_code, prompt=sample["prompt"],
            expected_provider=sample["provider"], reference_corpus=reference_corpus,
        )
        time.sleep(0.5)

        # Step 2 – Generate structured feedback
        feedback = _generate_feedback(initial_code, sample["prompt"])

        # Step 3 – Repair (only when feedback exists)
        if feedback:
            try:
                repaired_code = generate(
                    REPAIR_SYSTEM_PROMPT,
                    _repair_prompt(initial_code, feedback, sample["prompt"])
                )
            except Exception as e:
                print(f"  [ERROR repair] {sample['id']}: {e}")
                repaired_code = initial_code
        else:
            repaired_code = initial_code   # already clean; no repair needed

        repaired_metrics = evaluate(
            code=repaired_code, prompt=sample["prompt"],
            expected_provider=sample["provider"], reference_corpus=reference_corpus,
        )

        delta = {k: round(repaired_metrics[k] - initial_metrics[k], 4) for k in initial_metrics}

        all_results.append({
            "id": sample["id"], "category": sample["category"],
            "provider": sample["provider"], "prompt": sample["prompt"],
            "initial_code":     initial_code,
            "feedback":         feedback,
            "repaired_code":    repaired_code,
            "initial_metrics":  initial_metrics,
            "repaired_metrics": repaired_metrics,
            "delta":            delta,
            "metrics":          repaired_metrics,   # primary metrics for aggregation
        })

        # Save both code versions
        for suffix, code in [("initial", initial_code), ("repaired", repaired_code)]:
            with open(os.path.join(OUTPUT_CODE_DIR, f"{sample['id']}_{suffix}.tf"), "w") as f:
                f.write(code)

        time.sleep(0.5)

    # Aggregate repaired and initial separately
    aggregated    = aggregate_results([r["metrics"]          for r in all_results])
    initial_agg   = aggregate_results([r["initial_metrics"]  for r in all_results])
    final_score   = compute_final_score(aggregated)
    initial_score = compute_final_score(initial_agg)

    summary = {
        "experiment_id":       EXPERIMENT_ID,
        "experiment_name":     EXPERIMENT_NAME,
        "total_samples":       len(all_results),
        "initial_aggregated":  initial_agg,
        "initial_final_score": initial_score,
        "repaired_aggregated": aggregated,
        "final_score":         final_score,
        "improvement":         round(final_score - initial_score, 2),
        "results":             all_results,
    }
    with open(RESULTS_FILE, "w") as f:
        json.dump(summary, f, indent=2)

    print(f"\n  Results → {RESULTS_FILE}")
    print(f"\n  ── Initial  Metrics ────────────────────────────────")
    for k, v in initial_agg.items():
        print(f"     {k:<30}: {v}")
    print(f"\n  ── Repaired Metrics ────────────────────────────────")
    for k, v in aggregated.items():
        print(f"     {k:<30}: {v}")
    print(f"\n  ── Initial  Score : {initial_score} / 100")
    print(f"  ── Repaired Score : {final_score} / 100")
    print(f"  ── Improvement    : +{final_score - initial_score:.2f} points ──\n")
    return summary


if __name__ == "__main__":
    run()
