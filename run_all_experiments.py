"""
run_all_experiments.py
Master runner – executes all 9 experiments in sequence and produces
the final comparative results table for the LJMU thesis.

Usage:
    python run_all_experiments.py                         # run all 9
    python run_all_experiments.py --only E01 E04 E09      # run specific ones
"""

from __future__ import annotations
import json
import os
import sys
import argparse
from datetime import datetime

from config import RESULTS_DIR, OUTPUT_DIR

import E01_ZeroShot
import E02_ProviderSpecific
import E03_FewShot
import E04_DenseRAG
import E05_SparseRAG
import E06_HybridRAG
import E07_DependencyRAG
import E08_SecurityAware
import E09_ValidationRepair

EXPERIMENTS = {
    "E01": ("Zero-Shot Baseline",          E01_ZeroShot.run),
    "E02": ("Provider-Specific Prompting", E02_ProviderSpecific.run),
    "E03": ("Few-Shot TerraDS",            E03_FewShot.run),
    "E04": ("Dense RAG",                   E04_DenseRAG.run),
    "E05": ("Sparse BM25 RAG",             E05_SparseRAG.run),
    "E06": ("Hybrid RAG",                  E06_HybridRAG.run),
    "E07": ("Dependency-Aware RAG",        E07_DependencyRAG.run),
    "E08": ("Security-Aware Generation",   E08_SecurityAware.run),
    "E09": ("Validation Feedback Repair",  E09_ValidationRepair.run),
}

METRIC_LABELS = {
    "hcl_syntax_valid":       "HCL Syntax %",
    "format_pass":            "Format Pass %",
    "validation_pass":        "Validation %",
    "provider_correctness":   "Provider %",
    "resource_coverage":      "Coverage %",
    "dependency_correctness": "Dependency %",
    "security_issue_count":   "Sec Issues ↓",
    "hardcoded_secret_count": "Secrets ↓",
    "best_practice_score":    "Best-Practice %",
    "code_similarity_score":  "Similarity %",
}

SUMMARY_FILE = os.path.join(RESULTS_DIR, "final_comparison_table.json")
CSV_FILE     = os.path.join(RESULTS_DIR, "final_comparison_table.csv")
TXT_FILE     = os.path.join(RESULTS_DIR, "final_comparison_table.txt")


# ─────────────────────────────────────────────────────────────────────────────

def run_experiments(selected: list[str]) -> dict:
    summaries = {}
    for exp_id in selected:
        name, fn = EXPERIMENTS[exp_id]
        print(f"\n{'#'*60}")
        print(f"# Running {exp_id}: {name}")
        print(f"{'#'*60}")
        try:
            summaries[exp_id] = fn()
        except Exception as e:
            print(f"\n  [FAILED] {exp_id}: {e}")
            summaries[exp_id] = {"error": str(e)}
    return summaries


def build_comparison_table(summaries: dict) -> list[dict]:
    rows = []
    for exp_id, summary in summaries.items():
        if "error" in summary:
            continue
        # E09 stores its primary metrics under "repaired_aggregated"
        agg = summary.get("aggregated") or summary.get("repaired_aggregated", {})
        row = {
            "experiment_id":   exp_id,
            "experiment_name": summary.get("experiment_name", ""),
        }
        row.update(agg)
        row["final_score"] = summary.get("final_score", 0)
        rows.append(row)
    rows.sort(key=lambda r: r.get("final_score", 0), reverse=True)
    for rank, row in enumerate(rows, 1):
        row["rank"] = rank
    return rows


def save_csv(rows: list[dict]):
    if not rows:
        return
    headers = (
        ["rank", "experiment_id", "experiment_name"]
        + list(METRIC_LABELS.keys())
        + ["final_score"]
    )
    lines = [",".join(headers)]
    for row in rows:
        vals = []
        for h in headers:
            v = row.get(h, "")
            vals.append(f"{v:.4f}" if isinstance(v, float) else str(v))
        lines.append(",".join(vals))
    with open(CSV_FILE, "w") as f:
        f.write("\n".join(lines))
    print(f"\n  CSV  → {CSV_FILE}")


def save_txt(rows: list[dict]):
    if not rows:
        return
    metric_keys = list(METRIC_LABELS.keys())

    # Build header
    header = (
        f"{'Rank':<5} {'ID':<5} {'Experiment Name':<32} "
        + "  ".join(f"{METRIC_LABELS[k][:13]:<13}" for k in metric_keys)
        + f"  {'Score/100':>9}  "
    )
    sep = "─" * len(header)

    lines = [
        "LJMU Thesis – Terraform Generation Experiment Comparison",
        f"Generated : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"Model     : LLaMA 3.3 70B via api.together.ai",
        f"Samples   : 300  |  RAG: ChromaDB (dense) + BM25 (sparse)",
        sep, header, sep,
    ]

    for row in rows:
        metric_vals = "  ".join(
            f"{row.get(k, 0):<13.4f}" for k in metric_keys
        )
        lines.append(
            f"{row.get('rank', '-'):<5} {row['experiment_id']:<5} "
            f"{row['experiment_name']:<32} "
            + metric_vals
            + f"  {row.get('final_score', 0):>9.2f}"
        )

    lines += [
        sep,
        "",
        "Notes:",
        "  All % metrics: higher is better  |  Sec Issues & Secrets: lower is better (↓)",
        "  Final Score: weighted composite 0–100 per thesis scoring logic",
        "",
        "Weights: HCL Syntax 15% | Format 10% | Validation 15% | Provider 15%",
        "         Coverage 15% | Dependency 10% | Best-Practice 10%",
        "         Security Reduction 5% | Secret Reduction 5%",
    ]

    content = "\n".join(lines)
    with open(TXT_FILE, "w") as f:
        f.write(content)
    print(content)
    print(f"\n  TXT  → {TXT_FILE}")


# ─────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="LJMU Thesis Terraform Experiments")
    parser.add_argument(
        "--only", nargs="+", choices=list(EXPERIMENTS.keys()),
        help="Run only specific experiments e.g. --only E01 E04 E09"
    )
    args = parser.parse_args()

    selected = args.only or list(EXPERIMENTS.keys())
    print(f"\nExperiments : {', '.join(selected)}")
    print(f"Samples     : 300 per experiment")
    print(f"Output dir  : {OUTPUT_DIR}\n")

    summaries = run_experiments(selected)
    rows      = build_comparison_table(summaries)

    with open(SUMMARY_FILE, "w") as f:
        json.dump({"generated_at": datetime.now().isoformat(), "rows": rows}, f, indent=2)
    print(f"\n  JSON → {SUMMARY_FILE}")

    save_csv(rows)
    save_txt(rows)

    print(f"\n{'='*60}")
    print(f"  All done. Results in: {RESULTS_DIR}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
