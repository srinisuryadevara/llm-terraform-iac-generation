"""
E02_ProviderSpecific.py
Experiment 2: Provider-Specific Prompting
Purpose  : Evaluate whether provider-locked instructions improve Terraform
           code generation accuracy across AWS, Azure, and GCP.
Samples  : 300
Model    : LLaMA 3.3 70B via Together AI
"""

import json
import os
import time
from tqdm import tqdm

from config import RESULTS_DIR, OUTPUT_DIR
from dataset_loader import build_test_prompts, load_modules
from llm_client import generate, SYSTEM_TERRAFORM
from evaluator import evaluate, aggregate_results, compute_final_score

EXPERIMENT_ID   = "E02"
EXPERIMENT_NAME = "Provider-Specific Prompting"
RESULTS_FILE    = os.path.join(RESULTS_DIR, "E02_ProviderSpecific_results.json")
OUTPUT_CODE_DIR = os.path.join(OUTPUT_DIR,  "E02_ProviderSpecific_generated")
os.makedirs(OUTPUT_CODE_DIR, exist_ok=True)

PROVIDER_INSTRUCTIONS = {
    "aws": (
        "IMPORTANT: Use ONLY AWS Terraform provider resources. "
        "All resource types MUST start with 'aws_'. "
        "Do NOT use azurerm_, google_, or any other provider. "
        "Include: provider \"aws\" { region = var.region }"
    ),
    "azurerm": (
        "IMPORTANT: Use ONLY Azure Terraform provider (azurerm) resources. "
        "All resource types MUST start with 'azurerm_'. "
        "Do NOT use aws_, google_, or any other provider. "
        "Include: provider \"azurerm\" { features {} }"
    ),
    "google": (
        "IMPORTANT: Use ONLY Google Cloud (GCP) Terraform provider resources. "
        "All resource types MUST start with 'google_'. "
        "Do NOT use aws_, azurerm_, or any other provider. "
        "Include: provider \"google\" { project = var.project_id  region = var.region }"
    ),
    "multi": (
        "This is a multi-cloud requirement. Use separate provider blocks for "
        "AWS (aws_), Azure (azurerm_), and GCP (google_) as required. "
        "Each provider block must be declared explicitly."
    ),
    "security": (
        "Use the correct provider for the cloud described. "
        "Follow security best practices: no open ingress, no public storage, "
        "no hardcoded credentials."
    ),
    "dependency": (
        "Use the correct provider for the cloud described. "
        "All resource dependencies must use Terraform resource references "
        "(e.g. resource_type.resource_name.id). Never hardcode resource IDs."
    ),
}


def build_prompt(prompt_text: str, category: str, provider: str) -> str:
    instruction = PROVIDER_INSTRUCTIONS.get(category) or PROVIDER_INSTRUCTIONS.get(provider, "")
    return (
        f"{instruction}\n\n"
        "Generate complete Terraform HCL code for the following requirement:\n\n"
        f"{prompt_text}\n\n"
        "Output only valid Terraform HCL code. No explanations or markdown."
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
        user_prompt = build_prompt(sample["prompt"], sample["category"], sample["provider"])
        try:
            generated_code = generate(SYSTEM_TERRAFORM, user_prompt)
        except Exception as e:
            print(f"  [ERROR] {sample['id']}: {e}")
            generated_code = ""

        metrics = evaluate(
            code=generated_code,
            prompt=sample["prompt"],
            expected_provider=sample["provider"],
            reference_corpus=reference_corpus,
        )
        all_results.append({
            "id": sample["id"], "category": sample["category"],
            "provider": sample["provider"], "prompt": sample["prompt"],
            "generated_code": generated_code, "metrics": metrics,
        })
        with open(os.path.join(OUTPUT_CODE_DIR, f"{sample['id']}.tf"), "w") as f:
            f.write(generated_code)
        time.sleep(0.5)

    aggregated  = aggregate_results([r["metrics"] for r in all_results])
    final_score = compute_final_score(aggregated)

    summary = {
        "experiment_id": EXPERIMENT_ID, "experiment_name": EXPERIMENT_NAME,
        "total_samples": len(all_results),
        "aggregated": aggregated, "final_score": final_score,
        "results": all_results,
    }
    with open(RESULTS_FILE, "w") as f:
        json.dump(summary, f, indent=2)

    print(f"\n  Results → {RESULTS_FILE}")
    _print_metrics(aggregated, final_score)
    return summary


def _print_metrics(aggregated, final_score):
    print(f"\n  ── Aggregated Metrics ──────────────────────────────")
    for k, v in aggregated.items():
        print(f"     {k:<30}: {v}")
    print(f"\n  ── Final Weighted Score: {final_score} / 100 ──────\n")


if __name__ == "__main__":
    run()
