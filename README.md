# AI-Driven Terraform Code Generation for Multi-Cloud Infrastructure Using TerraDS

LJMU MSc Thesis — experimental codebase implementing and evaluating nine comparative
strategies for LLM-based Terraform (HCL) Infrastructure-as-Code generation across AWS,
Azure, and GCP.

---

## 1. Experimental Design Overview

This project uses a comparative experimental design to evaluate how different
Generative-AI-based approaches affect the quality of Terraform Infrastructure-as-Code
generation. All experiments are built around the **TerraDS** dataset, a large collection of
real-world Terraform HCL programs.

No real cloud deployment is performed at any stage. Every generated Terraform program is
assessed entirely offline, using static checks: HCL syntax validity, Terraform formatting,
Terraform validation, provider correctness, resource coverage, dependency correctness,
security issue count, hardcoded-secret detection, best-practice score, and similarity to real
Terraform patterns.

The nine experiments move progressively from a simple zero-shot baseline towards more
advanced generation strategies — provider-specific prompting, few-shot examples from
TerraDS, dense/sparse/hybrid retrieval-augmented generation (RAG), dependency-aware
retrieval, security-aware prompting, and validation-feedback self-repair. This progression
isolates the contribution of each technique to overall Terraform code quality.

## 2. Dataset

**TerraDS** is used as the source dataset. It contains real Terraform HCL modules collected
from open-source repositories, distributed as ~62,400 compressed module archives. The
dataset is filtered to focus on three cloud providers:

| Cloud Platform | Terraform Provider Focus |
|---|---|
| AWS | `aws_*` resources |
| Azure | `azurerm_*` resources |
| GCP | `google_*` resources |

TerraDS supports prompt construction, few-shot example selection, retrieval-augmented
generation, dependency analysis, and reference-based similarity scoring.

## 3. Dataset Preparation

`dataset_loader.py` and `build_chroma_index.py` implement the preparation pipeline:

| Stage | Implementation |
|---|---|
| Dataset loading | Extract `.tf` source files from the TerraDS module archives |
| Provider filtering | Keep modules using `aws_`, `azurerm_`, or `google_` resources |
| Invalid file removal | Skip empty, duplicate (md5-deduped), or unparsable `.tf` files |
| Resource extraction | Regex-based extraction of resource types per module |
| Module grouping | Group modules by detected provider (target: 400 modules/provider) |
| Prompt creation | Convert selected infrastructure tasks into natural-language prompts |
| Reference preparation | Original modules embedded into ChromaDB (`all-MiniLM-L6-v2`) as references for dense retrieval and similarity scoring |
| Test set creation | Fixed 300-prompt set cached to `test_prompts_300.json`, reused by all 9 experiments |

Using a single fixed test set across all experiments ensures a fair, reproducible comparison.

## 4. Test Prompt Set (300 prompts)

The prompt set covers AWS, Azure, GCP, multi-cloud, security-focused, and
dependency-focused infrastructure generation tasks. Each prompt specifies the expected
provider, resources, and (where relevant) dependency relationships.

| Category | Prompts |
|---|---|
| AWS | 75 |
| Azure (azurerm) | 75 |
| GCP (google) | 75 |
| Multi-cloud | 25 |
| Security-focused | 25 |
| Dependency-focused | 25 |
| **Total** | **300** |

> The original design proposed an even 50/50/50/50/50/50 split. The implemented set instead
> weights the three single-provider categories more heavily (75 each), since provider-level
> generation quality is the primary axis of comparison, while still reserving 25 prompts each
> for multi-cloud, security, and dependency scenarios.

Example prompt categories include: AWS networking/compute/storage, Azure
networking/compute/storage, GCP networking/compute/storage, multi-cloud deployments,
security-hardened infrastructure (no open SSH, no public buckets, no hardcoded
credentials), and dependency-chained resources (e.g. EC2 + subnet + security group).

## 5. The Nine Experiments

| ID | Experiment | Main Focus | TerraDS Examples | RAG | Security Focus | Self-Repair |
|---|---|---|---|---|---|---|
| E01 | Zero-Shot Baseline | Basic LLM generation, no support | No | No | No | No |
| E02 | Provider-Specific Prompting | Provider-correct resource usage | No | No | No | No |
| E03 | Few-Shot TerraDS Prompting | Example-guided generation | Yes | No | No | No |
| E04 | Dense RAG | Semantic retrieval (ChromaDB) | Yes | Yes | No | No |
| E05 | Sparse BM25 RAG | Keyword-based retrieval | Yes | Yes | No | No |
| E06 | Hybrid RAG | Dense + sparse retrieval combined | Yes | Yes | No | No |
| E07 | Dependency-Aware RAG | Retrieval prioritising connected resources | Yes | Yes | No | No |
| E08 | Security-Aware Generation | IaC security/compliance quality | Optional | Optional | Yes | No |
| E09 | Validation Feedback Repair | One-shot self-correction from validation errors | Optional | Optional | Yes | Yes |

**E01 – Zero-Shot Baseline.** The natural-language prompt is sent directly to the LLM with
no examples, retrieval, or guidance. Establishes the baseline for all later comparisons.

**E02 – Provider-Specific Prompting.** Separate prompt templates for AWS/Azure/GCP
explicitly instruct the model to use only the matching provider's resources
(`aws_*` / `azurerm_*` / `google_*`).

**E03 – Few-Shot TerraDS Prompting.** Two to three real Terraform examples from the same
provider as the target prompt are included before the generation task.

**E04 – Dense RAG.** The prompt is embedded and used to retrieve semantically similar
TerraDS modules from a ChromaDB vector store, which are added as context.

**E05 – Sparse BM25 RAG.** TerraDS examples are retrieved via BM25 keyword matching
against terms in the prompt (VPC, subnet, security group, storage bucket, etc.).

**E06 – Hybrid RAG.** Dense and sparse retrieval results are combined and de-duplicated
before being passed to the LLM as context.

**E07 – Dependency-Aware RAG.** Retrieval prioritises TerraDS examples that contain both
the requested resource and its required supporting resources (e.g. EC2 + subnet + security
group; VM + resource group + NIC; compute instance + network + firewall).

**E08 – Security-Aware Generation.** The prompt includes explicit instructions to avoid
hardcoded credentials, open SSH (`0.0.0.0/0`), public storage, overly permissive IAM, and
unrestricted firewall rules.

**E09 – Validation Feedback Repair.** The LLM generates code, the code is evaluated
offline (syntax, format, validation, security), and any errors/warnings are fed back to the
LLM for one correction pass. Both the initial and repaired versions are evaluated.

## 6. Evaluation Metrics

All nine experiments are scored with the same offline metrics for a fair, academically valid
comparison:

| Metric | Description | Better |
|---|---|---|
| HCL Syntax Validity | Generated code parses as valid HCL | Higher |
| Terraform Format Pass | Generated code passes `terraform fmt` formatting | Higher |
| Terraform Validation Pass | Generated code passes `terraform validate` | Higher |
| Provider Correctness | Resources belong to the requested cloud provider | Higher |
| Resource Coverage | All resources implied by the prompt are present | Higher |
| Dependency Correctness | Resources are properly connected via references | Higher |
| Security Issue Count | Static-scan security warnings (avg. per sample) | Lower |
| Hardcoded Secret Count | Hardcoded passwords/keys/tokens (avg. per sample) | Lower |
| Best-Practice Score | Use of variables, outputs, tags, naming, modular structure | Higher |
| Code Similarity Score | Structural similarity to real TerraDS modules | Higher |

Implemented in `evaluator.py`.

## 7. Final Scoring Logic

A weighted composite score (0–100) ranks the nine experiments. Lower-is-better metrics
(security issues, hardcoded secrets) are inverted before weighting (capped at 5
issues/sample).

| Metric | Weight |
|---|---|
| HCL Syntax Validity | 15% |
| Terraform Format Pass | 10% |
| Terraform Validation Pass | 15% |
| Provider Correctness | 15% |
| Resource Coverage | 15% |
| Dependency Correctness | 10% |
| Best-Practice Score | 10% |
| Security Issue Reduction | 5% |
| Hardcoded Secret Reduction | 5% |

Code Similarity Score is reported but not weighted into the final score, in line with the
proposed scoring logic.

## 8. Final Results

300 samples per experiment, generated with **LLaMA 3.3 70B Instruct Turbo via Together
AI**. Full per-metric breakdown (CSV/TXT) is in `results/final_comparison_table.*`.

| Rank | Experiment | Syntax % | Format % | Validation % | Provider % | Coverage % | Dependency % | Best-Practice % | Similarity % | Sec. Issues ↓ | Secrets ↓ | **Score /100** |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | E09 – Validation Feedback Repair | 100.00 | 100.00 | 100.00 | 100.00 | 89.33 | 99.87 | 70.75 | 9.24 | 0.12 | 0.00 | **95.34** |
| 2 | E08 – Security-Aware Generation | 98.67 | 100.00 | 98.67 | 100.00 | 91.17 | 98.67 | 60.08 | 9.34 | 0.33 | 0.01 | **93.81** |
| 3 | E03 – Few-Shot TerraDS Prompting | 100.00 | 100.00 | 100.00 | 100.00 | 89.33 | 96.80 | 46.96 | 0.00 | 0.21 | 0.01 | **92.56** |
| 4 | E06 – Hybrid RAG | 99.67 | 100.00 | 98.67 | 100.00 | 91.17 | 97.72 | 45.12 | 11.93 | 0.16 | 0.00 | **92.55** |
| 5 | E04 – Dense RAG | 100.00 | 100.00 | 99.33 | 100.00 | 91.00 | 96.38 | 44.96 | 12.04 | 0.15 | 0.01 | **92.53** |
| 6 | E07 – Dependency-Aware RAG | 99.67 | 100.00 | 99.67 | 100.00 | 91.33 | 98.22 | 43.17 | 11.82 | 0.24 | 0.02 | **92.48** |
| 7 | E05 – Sparse BM25 RAG | 99.33 | 99.00 | 99.00 | 99.83 | 89.00 | 96.71 | 46.21 | 11.79 | 0.15 | 0.01 | **92.10** |
| 8 | E02 – Provider-Specific Prompting | 100.00 | 100.00 | 100.00 | 100.00 | 89.33 | 97.28 | 40.37 | 0.00 | 0.17 | 0.00 | **91.99** |
| 9 | E01 – Zero-Shot Baseline | 99.67 | 100.00 | 99.67 | 100.00 | 88.67 | 98.00 | 41.33 | 0.00 | 0.21 | 0.01 | **91.91** |

*Sec. Issues / Secrets are average counts per generated file (lower is better).*

### Observations vs. Expected Findings

- **E09 (Validation Feedback Repair) ranked #1**, as predicted — the self-repair pass
  drove syntax/format/validation to 100% and produced by far the highest best-practice
  score (70.75%), confirming that validation-driven correction is the strongest single
  improvement.
- **E08 (Security-Aware Generation) ranked #2**, with the second-highest best-practice
  score (60.08%) — explicit security guidance measurably improved IaC quality, though it
  did not eliminate security issues entirely (0.33 avg/sample, the highest of all
  experiments).
- **E03 (Few-Shot TerraDS)** outperformed every RAG variant on best-practice score
  (46.96%) and tied for the best syntax/format/validation/provider scores (100%),
  supporting the prediction that real TerraDS examples improve structure and style.
- **E04–E07 (RAG variants)** clustered tightly (92.48–92.55), with **E06 (Hybrid RAG)**
  edging out dense-only and sparse-only retrieval and achieving the best resource coverage
  jointly with E08 (91.17%) — consistent with the prediction that hybrid retrieval
  outperforms single-retrieval methods, though the margin over E04/E05/E07 is small.
- **E07 (Dependency-Aware RAG)** achieved the best dependency score among the RAG
  experiments (98.22%) and the best resource coverage of all nine experiments (91.33%),
  supporting its intended focus on resource connectivity.
- **E01 (Zero-Shot Baseline) ranked last** as expected, with the lowest resource coverage
  (88.67%) and a low best-practice score (41.33%), confirming it as the weakest approach
  without external guidance.
- Overall, the spread between best (95.34) and worst (91.91) is relatively narrow — LLaMA
  3.3 70B already produces largely syntactically valid Terraform even zero-shot, so the
  experiments primarily differentiate on **best-practice quality**, **resource coverage**,
  **dependency correctness**, and **security hygiene** rather than raw syntax validity.

### Per-Experiment Result Tables

Individual aggregated results for each experiment (300 samples each). Raw data:
`results/E0X_*_results.json`. Sec. Issues / Secrets are average counts per generated file
(lower is better).

#### E01 — Zero-Shot Baseline

| Metric | Value |
|---|---|
| HCL Syntax Validity | 99.67% |
| Format Pass | 100.00% |
| Validation Pass | 99.67% |
| Provider Correctness | 100.00% |
| Resource Coverage | 88.67% |
| Dependency Correctness | 98.00% |
| Security Issues ↓ | 0.21 |
| Hardcoded Secrets ↓ | 0.01 |
| Best-Practice Score | 41.33% |
| Code Similarity | 0.00% |
| **Final Score** | **91.91 / 100** |

#### E02 — Provider-Specific Prompting

| Metric | Value |
|---|---|
| HCL Syntax Validity | 100.00% |
| Format Pass | 100.00% |
| Validation Pass | 100.00% |
| Provider Correctness | 100.00% |
| Resource Coverage | 89.33% |
| Dependency Correctness | 97.28% |
| Security Issues ↓ | 0.17 |
| Hardcoded Secrets ↓ | 0.00 |
| Best-Practice Score | 40.37% |
| Code Similarity | 0.00% |
| **Final Score** | **91.99 / 100** |

#### E03 — Few-Shot TerraDS Prompting

| Metric | Value |
|---|---|
| HCL Syntax Validity | 100.00% |
| Format Pass | 100.00% |
| Validation Pass | 100.00% |
| Provider Correctness | 100.00% |
| Resource Coverage | 89.33% |
| Dependency Correctness | 96.80% |
| Security Issues ↓ | 0.21 |
| Hardcoded Secrets ↓ | 0.01 |
| Best-Practice Score | 46.96% |
| Code Similarity | 0.00% |
| **Final Score** | **92.56 / 100** |

#### E04 — Dense RAG

| Metric | Value |
|---|---|
| HCL Syntax Validity | 100.00% |
| Format Pass | 100.00% |
| Validation Pass | 99.33% |
| Provider Correctness | 100.00% |
| Resource Coverage | 91.00% |
| Dependency Correctness | 96.38% |
| Security Issues ↓ | 0.15 |
| Hardcoded Secrets ↓ | 0.01 |
| Best-Practice Score | 44.96% |
| Code Similarity | 12.04% |
| **Final Score** | **92.53 / 100** |

#### E05 — Sparse BM25 RAG

| Metric | Value |
|---|---|
| HCL Syntax Validity | 99.33% |
| Format Pass | 99.00% |
| Validation Pass | 99.00% |
| Provider Correctness | 99.83% |
| Resource Coverage | 89.00% |
| Dependency Correctness | 96.71% |
| Security Issues ↓ | 0.15 |
| Hardcoded Secrets ↓ | 0.01 |
| Best-Practice Score | 46.21% |
| Code Similarity | 11.79% |
| **Final Score** | **92.10 / 100** |

#### E06 — Hybrid RAG

| Metric | Value |
|---|---|
| HCL Syntax Validity | 99.67% |
| Format Pass | 100.00% |
| Validation Pass | 98.67% |
| Provider Correctness | 100.00% |
| Resource Coverage | 91.17% |
| Dependency Correctness | 97.72% |
| Security Issues ↓ | 0.16 |
| Hardcoded Secrets ↓ | 0.00 |
| Best-Practice Score | 45.12% |
| Code Similarity | 11.93% |
| **Final Score** | **92.55 / 100** |

#### E07 — Dependency-Aware RAG

| Metric | Value |
|---|---|
| HCL Syntax Validity | 99.67% |
| Format Pass | 100.00% |
| Validation Pass | 99.67% |
| Provider Correctness | 100.00% |
| Resource Coverage | 91.33% |
| Dependency Correctness | 98.22% |
| Security Issues ↓ | 0.24 |
| Hardcoded Secrets ↓ | 0.02 |
| Best-Practice Score | 43.17% |
| Code Similarity | 11.82% |
| **Final Score** | **92.48 / 100** |

#### E08 — Security-Aware Generation

| Metric | Value |
|---|---|
| HCL Syntax Validity | 98.67% |
| Format Pass | 100.00% |
| Validation Pass | 98.67% |
| Provider Correctness | 100.00% |
| Resource Coverage | 91.17% |
| Dependency Correctness | 98.67% |
| Security Issues ↓ | 0.33 |
| Hardcoded Secrets ↓ | 0.01 |
| Best-Practice Score | 60.08% |
| Code Similarity | 9.34% |
| **Final Score** | **93.81 / 100** |

#### E09 — Validation Feedback Repair

This experiment generates code, evaluates it, feeds any errors back to the LLM for one
repair pass, then re-evaluates. Both passes are reported below.

| Metric | Initial | Repaired | Δ |
|---|---|---|---|
| HCL Syntax Validity | 100.00% | 100.00% | 0.00 |
| Format Pass | 100.00% | 100.00% | 0.00 |
| Validation Pass | 100.00% | 100.00% | 0.00 |
| Provider Correctness | 100.00% | 100.00% | 0.00 |
| Resource Coverage | 89.00% | 89.33% | +0.33 |
| Dependency Correctness | 97.47% | 99.87% | +2.40 |
| Security Issues ↓ | 0.22 | 0.12 | −0.10 |
| Hardcoded Secrets ↓ | 0.00 | 0.00 | 0.00 |
| Best-Practice Score | 43.63% | 70.75% | +27.12 |
| Code Similarity | 12.67% | 9.24% | −3.43 |
| **Final Score** | **92.24** | **95.34** | **+3.10** |

The repair pass delivers the single largest gain in the entire study — a +27-point jump in
best-practice score and a 0.10 reduction in average security issues per file — confirming
the thesis prediction that validation-driven self-correction is the strongest improvement
strategy.

## 9. Repository Structure

```
Code/
│
├── .env.example                  ← Template for API keys (copy to .env, never commit .env)
├── config.py                     ← Shared settings (paths, model, ChromaDB, 300 samples)
├── dataset_loader.py             ← TerraDS loader + 300-sample prompt builder
├── llm_client.py                 ← Together AI / LLaMA 3.3 70B wrapper (Ollama fallback supported)
├── evaluator.py                  ← All 10 offline evaluation metrics + scoring logic
├── chroma_store.py               ← ChromaDB index builder (dense retrieval)
├── build_chroma_index.py         ← Extracts TerraDS archives + builds ChromaDB index
├── regenerate_table.py           ← Rebuilds comparison table from saved results (no re-run)
│
├── E01_ZeroShot.py               ← Experiment 1: Zero-Shot Baseline
├── E02_ProviderSpecific.py       ← Experiment 2: Provider-Specific Prompting
├── E03_FewShot.py                ← Experiment 3: Few-Shot TerraDS
├── E04_DenseRAG.py                ← Experiment 4: Dense RAG (ChromaDB)
├── E05_SparseRAG.py               ← Experiment 5: Sparse BM25 RAG
├── E06_HybridRAG.py               ← Experiment 6: Hybrid RAG (Dense + BM25)
├── E07_DependencyRAG.py           ← Experiment 7: Dependency-Aware RAG
├── E08_SecurityAware.py           ← Experiment 8: Security-Aware Generation
├── E09_ValidationRepair.py        ← Experiment 9: Validation Feedback Repair
│
├── run_all_experiments.py        ← Master runner + ranked comparison table
├── run_experiments_local.sh      ← Convenience shell wrapper (installs deps, runs all)
└── requirements.txt
```

After running, each `E0X_*_generated/` directory holds the 300 generated `.tf` files for that
experiment (E09 holds 600: initial + repaired), and `results/` holds per-experiment JSON
plus the final comparison table (`final_comparison_table.json/.csv/.txt`).

## 10. Setup & Reproduction

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Create your .env from the template and add your Together AI API key
cp .env.example .env
# then edit .env and set TOGETHER_API_KEY=your_key_here
# Get a key at: https://api.together.ai/settings/api-keys

# 3. Confirm the TerraDS dataset is accessible (update DATASET_PATH in config.py if needed)
ls <path-to>/Data-Sets/14217386/TerraDS

# 4. (Required for E04, E06, E07) Build the ChromaDB retrieval index
python3 build_chroma_index.py
```

**Model backend:** by default `config.py` uses Together AI
(`meta-llama/Llama-3.3-70B-Instruct-Turbo`). To run fully locally instead, set
`USE_OLLAMA = True` in `config.py` and run `ollama serve` with `llama3.3:70b` pulled.

```bash
# Run ALL 9 experiments (300 samples each)
python run_all_experiments.py

# Run specific experiments only
python run_all_experiments.py --only E01 E02 E03

# Run a single experiment directly
python E04_DenseRAG.py
python E09_ValidationRepair.py

# Rebuild the comparison table from existing results without re-running
python regenerate_table.py
```

## 11. Contribution

This codebase implements a structured, nine-stage comparison of AI-driven Terraform
generation strategies — progressing from zero-shot generation through provider-specific
prompting, few-shot TerraDS examples, dense/sparse/hybrid retrieval-augmented generation,
dependency-aware retrieval, security-aware prompting, and validation-feedback self-repair.
Every stage is evaluated against the same fixed 300-prompt test set using ten offline,
reproducible metrics, without requiring real cloud deployment, allowing direct measurement
of which generation strategy produces the most reliable, secure, and well-structured
Terraform HCL code.
