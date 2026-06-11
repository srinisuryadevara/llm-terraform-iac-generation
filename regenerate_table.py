"""
regenerate_table.py
Rebuilds the final comparison table from already-saved per-experiment
results JSON files, without re-running any experiments.
"""

import json
import os
from datetime import datetime

from config import RESULTS_DIR
from run_all_experiments import build_comparison_table, save_csv, save_txt, EXPERIMENTS, SUMMARY_FILE

RESULT_FILES = {
    "E01": "E01_ZeroShot_results.json",
    "E02": "E02_ProviderSpecific_results.json",
    "E03": "E03_FewShot_results.json",
    "E04": "E04_DenseRAG_results.json",
    "E05": "E05_SparseRAG_results.json",
    "E06": "E06_HybridRAG_results.json",
    "E07": "E07_DependencyRAG_results.json",
    "E08": "E08_SecurityAware_results.json",
    "E09": "E09_ValidationRepair_results.json",
}

summaries = {}
for exp_id, fname in RESULT_FILES.items():
    path = os.path.join(RESULTS_DIR, fname)
    if os.path.exists(path):
        with open(path) as f:
            summaries[exp_id] = json.load(f)
    else:
        print(f"  [skip] {exp_id}: {fname} not found")

rows = build_comparison_table(summaries)

with open(SUMMARY_FILE, "w") as f:
    json.dump({"generated_at": datetime.now().isoformat(), "rows": rows}, f, indent=2)
print(f"\n  JSON → {SUMMARY_FILE}")

save_csv(rows)
save_txt(rows)
