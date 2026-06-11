"""
E03_FewShot.py
Experiment 3: Few-Shot Terraform Generation Using TerraDS Examples
Purpose  : Evaluate whether real TerraDS examples prepended to each prompt
           improve Terraform code quality (syntax, style, completeness).
Samples  : 300
Model    : LLaMA 3.3 70B via Together AI
"""

from __future__ import annotations
import json
import os
import random
import time
from tqdm import tqdm

from config import RESULTS_DIR, OUTPUT_DIR, RANDOM_SEED
from dataset_loader import build_test_prompts, load_modules
from llm_client import generate, SYSTEM_TERRAFORM
from evaluator import evaluate, aggregate_results, compute_final_score

EXPERIMENT_ID   = "E03"
EXPERIMENT_NAME = "Few-Shot TerraDS Prompting"
RESULTS_FILE    = os.path.join(RESULTS_DIR, "E03_FewShot_results.json")
OUTPUT_CODE_DIR = os.path.join(OUTPUT_DIR,  "E03_FewShot_generated")
os.makedirs(OUTPUT_CODE_DIR, exist_ok=True)

NUM_EXAMPLES = 2   # TerraDS examples per prompt


def select_examples(modules: dict, provider: str, n: int = NUM_EXAMPLES) -> list[str]:
    pool = modules.get(provider, [])
    if not pool:
        pool = [m for mods in modules.values() for m in mods]
    selected = random.sample(pool, min(n, len(pool)))
    return [m["content"] for m in selected]


def build_prompt(prompt_text: str, examples: list[str]) -> str:
    block = "".join(
        f"\n--- Example {i} ---\n{(ex[:1500] if len(ex) > 1500 else ex)}\n"
        for i, ex in enumerate(examples, 1)
    )
    return (
        f"Below are {len(examples)} real Terraform HCL examples from production "
        f"repositories to guide your code style, structure, and resource usage:\n"
        f"{block}\n"
        f"--- Task ---\n"
        f"Now generate complete Terraform HCL code for the following requirement:\n\n"
        f"{prompt_text}\n\n"
        "Follow the style and structure shown in the examples. "
        "Output only valid Terraform HCL code. No explanations."
    )


def run():
    print(f"\n{'='*60}")
    print(f"  {EXPERIMENT_ID}: {EXPERIMENT_NAME}  |  300 samples")
    print(f"{'='*60}\n")

    random.seed(RANDOM_SEED)
    prompts = build_test_prompts()
    modules = load_modules()
    reference_corpus = [
        m["content"] for mods in modules.values() for m in mods[:50]
    ]

    all_results = []

    for sample in tqdm(prompts, desc=EXPERIMENT_ID):
        provider = sample["provider"] if sample["provider"] in modules else "aws"
        examples = select_examples(modules, provider)
        user_prompt = build_prompt(sample["prompt"], examples)
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
            "examples_used": [ex[:200] + "..." for ex in examples],
            "generated_code": generated_code, "metrics": metrics,
        })
        with open(os.path.join(OUTPUT_CODE_DIR, f"{sample['id']}.tf"), "w") as f:
            f.write(generated_code)
        time.sleep(0.5)

    aggregated  = aggregate_results([r["metrics"] for r in all_results])
    final_score = compute_final_score(aggregated)

    summary = {
        "experiment_id": EXPERIMENT_ID, "experiment_name": EXPERIMENT_NAME,
        "num_examples": NUM_EXAMPLES, "total_samples": len(all_results),
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
