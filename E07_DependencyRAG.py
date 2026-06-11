"""
E07_DependencyRAG.py
Experiment 7: Dependency-Aware RAG Generation
Purpose  : Retrieve TerraDS examples that contain BOTH the requested resource
           AND its required dependent resources (e.g. EC2 + subnet + SG).
           Re-ranks dense results by dependency resource coverage score.
Samples  : 300
Model    : LLaMA 3.3 70B via Together AI
RAG      : ChromaDB (dense) re-ranked by dependency coverage
"""

from __future__ import annotations
import json
import os
import re
import time
from tqdm import tqdm

from config import RESULTS_DIR, OUTPUT_DIR
from dataset_loader import build_test_prompts, load_modules
from chroma_store import dense_retrieve
from llm_client import generate, SYSTEM_TERRAFORM
from evaluator import evaluate, aggregate_results, compute_final_score

EXPERIMENT_ID   = "E07"
EXPERIMENT_NAME = "Dependency-Aware RAG"
RESULTS_FILE    = os.path.join(RESULTS_DIR, "E07_DependencyRAG_results.json")
OUTPUT_CODE_DIR = os.path.join(OUTPUT_DIR,  "E07_DependencyRAG_generated")
os.makedirs(OUTPUT_CODE_DIR, exist_ok=True)

TOP_K = 3

DEPENDENCY_MAP = {
    "ec2":              ["aws_instance",                   "aws_subnet",           "aws_security_group"],
    "instance":         ["aws_instance",                   "aws_subnet",           "aws_security_group"],
    "rds":              ["aws_db_instance",                "aws_db_subnet_group",  "aws_security_group"],
    "eks":              ["aws_eks_cluster",                "aws_eks_node_group",   "aws_iam_role"],
    "lambda":           ["aws_lambda_function",            "aws_iam_role",         "aws_cloudwatch_log_group"],
    "alb":              ["aws_lb",                         "aws_lb_target_group",  "aws_lb_listener"],
    "ecs":              ["aws_ecs_cluster",                "aws_ecs_task_definition", "aws_ecs_service"],
    "virtual machine":  ["azurerm_linux_virtual_machine",  "azurerm_network_interface", "azurerm_subnet"],
    "aks":              ["azurerm_kubernetes_cluster",      "azurerm_resource_group"],
    "sql":              ["azurerm_sql_server",              "azurerm_sql_database", "azurerm_resource_group"],
    "app service":      ["azurerm_app_service",            "azurerm_app_service_plan"],
    "function app":     ["azurerm_function_app",           "azurerm_storage_account", "azurerm_app_service_plan"],
    "compute instance": ["google_compute_instance",        "google_compute_network", "google_compute_subnetwork"],
    "gke":              ["google_container_cluster",        "google_container_node_pool"],
    "cloud sql":        ["google_sql_database_instance",   "google_sql_database"],
    "cloud run":        ["google_cloud_run_service",        "google_service_account"],
    "cloud functions":  ["google_cloudfunctions_function",  "google_service_account"],
}


def _extract_deps(prompt: str) -> list[str]:
    prompt_lower = prompt.lower()
    deps = []
    for kw, resources in DEPENDENCY_MAP.items():
        if kw in prompt_lower:
            deps.extend(resources)
    return list(set(deps))


def _dep_score(content: str, deps: list[str]) -> int:
    return sum(1 for d in deps if d in content)


def _dep_retrieve(prompt: str, provider: str, top_k: int = TOP_K) -> list[str]:
    expected_deps = _extract_deps(prompt)
    candidates    = dense_retrieve(prompt, provider=provider, top_k=top_k * 3)
    if not expected_deps:
        return candidates[:top_k]
    ranked = sorted(candidates, key=lambda d: _dep_score(d, expected_deps), reverse=True)
    return ranked[:top_k]


def build_prompt(prompt_text: str, retrieved: list[str], expected_deps: list[str]) -> str:
    block = "".join(
        f"\n--- Dependency-Aware Retrieved Example {i} ---\n{(doc[:1500] if len(doc) > 1500 else doc)}\n"
        for i, doc in enumerate(retrieved, 1)
    )
    dep_hint = (
        f"\nExpected dependent resources to include: {', '.join(expected_deps)}\n"
        if expected_deps else ""
    )
    return (
        "The following Terraform HCL modules were retrieved because they contain "
        "the main requested resource AND its required dependencies:\n"
        f"{block}\n"
        "--- Task ---\n"
        f"{dep_hint}"
        "Generate complete Terraform HCL code for the following requirement:\n\n"
        f"{prompt_text}\n\n"
        "IMPORTANT: All resources must be properly connected using Terraform references "
        "(e.g. resource_type.resource_name.attribute). Do NOT use hardcoded IDs.\n"
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
        provider      = sample["provider"] if sample["provider"] != "multi" else None
        expected_deps = _extract_deps(sample["prompt"])
        retrieved     = _dep_retrieve(sample["prompt"], provider)

        try:
            generated_code = generate(
                SYSTEM_TERRAFORM,
                build_prompt(sample["prompt"], retrieved, expected_deps)
            )
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
            "expected_deps": expected_deps, "retrieved_count": len(retrieved),
            "generated_code": generated_code, "metrics": metrics,
        })
        with open(os.path.join(OUTPUT_CODE_DIR, f"{sample['id']}.tf"), "w") as f:
            f.write(generated_code)
        time.sleep(0.5)

    aggregated  = aggregate_results([r["metrics"] for r in all_results])
    final_score = compute_final_score(aggregated)

    summary = {
        "experiment_id": EXPERIMENT_ID, "experiment_name": EXPERIMENT_NAME,
        "retrieval_type": "dependency_aware_dense_reranked", "top_k": TOP_K,
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
