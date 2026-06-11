"""
E04_DenseRAG.py
Experiment 4: Dense RAG-Based Terraform Generation
Purpose  : Semantic retrieval via ChromaDB to ground LLM generation with
           the most semantically similar TerraDS examples.
Samples  : 300
Model    : LLaMA 3.3 70B via Together AI
RAG      : ChromaDB (dense / semantic)
"""

from __future__ import annotations
import json
import os
import time
from tqdm import tqdm

from config import RESULTS_DIR, OUTPUT_DIR
from dataset_loader import build_test_prompts, load_modules
from chroma_store import dense_retrieve
from llm_client import generate, SYSTEM_TERRAFORM
from evaluator import evaluate, aggregate_results, compute_final_score

EXPERIMENT_ID   = "E04"
EXPERIMENT_NAME = "Dense RAG"
RESULTS_FILE    = os.path.join(RESULTS_DIR, "E04_DenseRAG_results.json")
OUTPUT_CODE_DIR = os.path.join(OUTPUT_DIR,  "E04_DenseRAG_generated")
os.makedirs(OUTPUT_CODE_DIR, exist_ok=True)

TOP_K = 3


def build_prompt(prompt_text: str, retrieved: list[str]) -> str:
    block = "".join(
        f"\n--- Retrieved Example {i} ---\n{(doc[:1500] if len(doc) > 1500 else doc)}\n"
        for i, doc in enumerate(retrieved, 1)
    )
    return (
        "The following Terraform HCL modules were retrieved from a real-world dataset "
        "as semantically similar examples to your task:\n"
        f"{block}\n"
        "--- Task ---\n"
        "Generate complete Terraform HCL code for the following requirement:\n\n"
        f"{prompt_text}\n\n"
        "Use the retrieved examples as a structural guide. "
        "Output only valid Terraform HCL code. No explanations."
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
        provider  = sample["provider"] if sample["provider"] != "multi" else None
        retrieved = dense_retrieve(sample["prompt"], provider=provider, top_k=TOP_K)
        try:
            generated_code = generate(SYSTEM_TERRAFORM, build_prompt(sample["prompt"], retrieved))
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
            "retrieved_count": len(retrieved),
            "generated_code": generated_code, "metrics": metrics,
        })
        with open(os.path.join(OUTPUT_CODE_DIR, f"{sample['id']}.tf"), "w") as f:
            f.write(generated_code)
        time.sleep(0.5)

    aggregated  = aggregate_results([r["metrics"] for r in all_results])
    final_score = compute_final_score(aggregated)

    summary = {
        "experiment_id": EXPERIMENT_ID, "experiment_name": EXPERIMENT_NAME,
        "retrieval_type": "dense_semantic_chromadb", "top_k": TOP_K,
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
