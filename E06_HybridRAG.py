"""
E06_HybridRAG.py
Experiment 6: Hybrid RAG-Based Terraform Generation
Purpose  : Combine dense (ChromaDB semantic) and sparse (BM25 keyword)
           retrieval, deduplicate results, and pass merged context to LLM.
Samples  : 300
Model    : LLaMA 3.3 70B via Together AI
RAG      : ChromaDB (dense) + BM25 (sparse) merged
"""

from __future__ import annotations
import json
import os
import time
from tqdm import tqdm

from config import RESULTS_DIR, OUTPUT_DIR
from dataset_loader import build_test_prompts, load_modules
from chroma_store import dense_retrieve
from E05_SparseRAG import BM25Index
from llm_client import generate, SYSTEM_TERRAFORM
from evaluator import evaluate, aggregate_results, compute_final_score

EXPERIMENT_ID   = "E06"
EXPERIMENT_NAME = "Hybrid RAG"
RESULTS_FILE    = os.path.join(RESULTS_DIR, "E06_HybridRAG_results.json")
OUTPUT_CODE_DIR = os.path.join(OUTPUT_DIR,  "E06_HybridRAG_generated")
os.makedirs(OUTPUT_CODE_DIR, exist_ok=True)

DENSE_K     = 2
SPARSE_K    = 2
MAX_CONTEXT = 3


def _merge(dense: list[str], sparse: list[str], max_k: int = MAX_CONTEXT) -> list[str]:
    seen, merged = set(), []
    for pair in zip(dense, sparse):
        for doc in pair:
            key = doc[:200]
            if key not in seen:
                seen.add(key)
                merged.append(doc)
    for doc in dense + sparse:
        if doc[:200] not in seen:
            seen.add(doc[:200])
            merged.append(doc)
    return merged[:max_k]


def build_prompt(prompt_text: str, retrieved: list[str]) -> str:
    block = "".join(
        f"\n--- Hybrid Retrieved Example {i} ---\n{(doc[:1500] if len(doc) > 1500 else doc)}\n"
        for i, doc in enumerate(retrieved, 1)
    )
    return (
        "The following Terraform HCL modules were retrieved using a hybrid approach "
        "combining semantic similarity and keyword matching:\n"
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

    corpus = [
        {"content": m["content"], "provider": provider}
        for provider, mods in modules.items() for m in mods
    ]
    print(f"  Building BM25 index over {len(corpus)} modules …")
    bm25 = BM25Index(corpus)
    reference_corpus = [m["content"] for m in corpus[:150]]

    all_results = []

    for sample in tqdm(prompts, desc=EXPERIMENT_ID):
        provider     = sample["provider"] if sample["provider"] != "multi" else None
        dense_docs   = dense_retrieve(sample["prompt"], provider=provider, top_k=DENSE_K)
        sparse_docs  = bm25.retrieve(sample["prompt"], provider=provider, top_k=SPARSE_K)
        merged       = _merge(dense_docs, sparse_docs)

        try:
            generated_code = generate(SYSTEM_TERRAFORM, build_prompt(sample["prompt"], merged))
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
            "dense_count": len(dense_docs), "sparse_count": len(sparse_docs),
            "merged_count": len(merged),
            "generated_code": generated_code, "metrics": metrics,
        })
        with open(os.path.join(OUTPUT_CODE_DIR, f"{sample['id']}.tf"), "w") as f:
            f.write(generated_code)
        time.sleep(0.5)

    aggregated  = aggregate_results([r["metrics"] for r in all_results])
    final_score = compute_final_score(aggregated)

    summary = {
        "experiment_id": EXPERIMENT_ID, "experiment_name": EXPERIMENT_NAME,
        "retrieval_type": "hybrid_dense_sparse",
        "dense_k": DENSE_K, "sparse_k": SPARSE_K,
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
