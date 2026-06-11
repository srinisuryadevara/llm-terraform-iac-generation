"""
E05_SparseRAG.py
Experiment 5: Sparse BM25 RAG-Based Terraform Generation
Purpose  : Keyword-based (BM25) retrieval to ground LLM generation.
           Best when prompts contain explicit Terraform resource terms.
Samples  : 300
Model    : LLaMA 3.3 70B via Together AI
RAG      : BM25 (no external library – built-in implementation)
"""

from __future__ import annotations
import json
import math
import os
import re
import time
from collections import Counter
from tqdm import tqdm

from config import RESULTS_DIR, OUTPUT_DIR
from dataset_loader import build_test_prompts, load_modules
from llm_client import generate, SYSTEM_TERRAFORM
from evaluator import evaluate, aggregate_results, compute_final_score

EXPERIMENT_ID   = "E05"
EXPERIMENT_NAME = "Sparse BM25 RAG"
RESULTS_FILE    = os.path.join(RESULTS_DIR, "E05_SparseRAG_results.json")
OUTPUT_CODE_DIR = os.path.join(OUTPUT_DIR,  "E05_SparseRAG_generated")
os.makedirs(OUTPUT_CODE_DIR, exist_ok=True)

TOP_K   = 3
BM25_K1 = 1.5
BM25_B  = 0.75


# ─── Lightweight BM25 (no external dependency) ────────────────────────────────

def _tokenize(text: str) -> list[str]:
    return re.findall(r"[a-z0-9_]+", text.lower())


class BM25Index:
    def __init__(self, corpus: list[dict]):
        self.corpus = corpus
        self.docs   = [_tokenize(d["content"]) for d in corpus]
        self.N      = len(self.docs)
        self.avgdl  = sum(len(d) for d in self.docs) / max(self.N, 1)
        self.df     = self._build_df()

    def _build_df(self) -> dict[str, int]:
        df = Counter()
        for doc in self.docs:
            for term in set(doc):
                df[term] += 1
        return df

    def _score(self, query: str) -> list[tuple[float, int]]:
        q_terms = _tokenize(query)
        scores  = []
        for idx, doc_tokens in enumerate(self.docs):
            tf = Counter(doc_tokens)
            dl = len(doc_tokens)
            s  = 0.0
            for term in q_terms:
                if term not in self.df:
                    continue
                idf = math.log(
                    (self.N - self.df[term] + 0.5) / (self.df[term] + 0.5) + 1
                )
                tf_norm = (tf[term] * (BM25_K1 + 1)) / (
                    tf[term] + BM25_K1 * (1 - BM25_B + BM25_B * dl / self.avgdl)
                )
                s += idf * tf_norm
            scores.append((s, idx))
        return sorted(scores, reverse=True)

    def retrieve(self, query: str, provider: str = None, top_k: int = TOP_K) -> list[str]:
        ranked  = self._score(query)
        results = []
        for _, idx in ranked:
            if len(results) >= top_k:
                break
            doc = self.corpus[idx]
            if provider and provider != "multi" and doc.get("provider") != provider:
                continue
            results.append(doc["content"])
        # Fill without filter if needed
        if len(results) < top_k:
            for _, idx in ranked:
                if len(results) >= top_k:
                    break
                content = self.corpus[idx]["content"]
                if content not in results:
                    results.append(content)
        return results


# ─────────────────────────────────────────────────────────────────────────────

def build_prompt(prompt_text: str, retrieved: list[str]) -> str:
    block = "".join(
        f"\n--- BM25 Retrieved Example {i} ---\n{(doc[:1500] if len(doc) > 1500 else doc)}\n"
        for i, doc in enumerate(retrieved, 1)
    )
    return (
        "The following Terraform HCL modules were retrieved using keyword matching "
        "based on your infrastructure terms:\n"
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
        provider  = sample["provider"] if sample["provider"] != "multi" else None
        retrieved = bm25.retrieve(sample["prompt"], provider=provider, top_k=TOP_K)
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
        "retrieval_type": "sparse_bm25", "top_k": TOP_K,
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
