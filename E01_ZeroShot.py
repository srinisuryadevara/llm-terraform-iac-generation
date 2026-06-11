"""
E01_ZeroShot.py
Experiment 1: Zero-Shot Terraform Code Generation
Purpose  : Baseline – LLM generates Terraform HCL directly from a natural-language
           prompt with NO examples, retrieval, security guidance, or repair feedback.
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

EXPERIMENT_ID   = "E01"
EXPERIMENT_NAME = "Zero-Shot Baseline"
RESULTS_FILE    = os.path.join(RESULTS_DIR, "E01_ZeroShot_results.json")
OUTPUT_CODE_DIR = os.path.join(OUTPUT_DIR,  "E01_ZeroShot_generated")
os.makedirs(OUTPUT_CODE_DIR, exist_ok=True)


def build_prompt(prompt_text: str) -> str:
    return (
        "Generate complete Terraform HCL code for the following infrastructure requirement:\n\n"
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
        try:
            generated_code = generate(SYSTEM_TERRAFORM, build_prompt(sample["prompt"]))
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
