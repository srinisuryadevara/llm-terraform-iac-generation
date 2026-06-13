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

## 8. End-to-End Code Walkthrough

This section describes how the codebase fits together and runs from start to finish, in
execution order.

### 8.1 Configuration (`config.py`)

The single source of shared settings, loaded by every other module:

- Reads `TOGETHER_API_KEY` (and an optional `GEMINI_API_KEY`) from a local `.env` file via
  `python-dotenv`. `.env` is git-ignored; `.env.example` documents the expected variables.
- Selects the LLM backend: **Together AI** running
  `meta-llama/Llama-3.3-70B-Instruct-Turbo` by default, or a fully local **Ollama**
  backend (`llama3.3:70b`) when `USE_OLLAMA = True`.
- Defines filesystem paths: `DATASET_PATH` (location of the TerraDS archives),
  `OUTPUT_DIR` (project root), `RESULTS_DIR` (`results/`), and `CHROMA_PERSIST_DIR`
  (`chroma_db/`), creating the latter two if missing.
- Fixes experiment-wide constants: `NUM_SAMPLES = 300` and `RANDOM_SEED = 42`, so every
  experiment runs against the same 300-prompt test set.
- Declares the three target providers (`aws`, `azurerm`, `google`) with their resource-name
  prefixes and display labels, used throughout prompt building and evaluation.

### 8.2 Dataset Preparation (`dataset_loader.py`, `build_chroma_index.py`, `chroma_store.py`)

- `dataset_loader.py` extracts `.tf` files from the TerraDS module archives, filters out
  modules that don't use `aws_`, `azurerm_`, or `google_` resources, removes empty /
  duplicate (MD5-deduped) / unparsable files, and extracts each module's resource types via
  regex. Modules are grouped by provider (targeting 400 modules per provider).
  `build_test_prompts()` turns a curated set of infrastructure tasks into the fixed
  300-prompt test set, caching the result to `test_prompts_300.json` so every experiment
  uses identical prompts. `load_modules()` returns the cleaned reference modules, used for
  few-shot examples, BM25/dependency retrieval, and similarity scoring.
- `chroma_store.py` wraps a ChromaDB collection (`terrads_collection`, persisted under
  `chroma_db/`) embedded with `all-MiniLM-L6-v2`.
- `build_chroma_index.py` is the one-time script that extracts the TerraDS archives and
  populates this ChromaDB index from the reference modules. It must be run once before any
  experiment that needs dense retrieval (E04, E06, E07).

### 8.3 LLM Access (`llm_client.py`)

A thin, backend-agnostic wrapper used by all nine experiments:

- `SYSTEM_TERRAFORM` defines the shared system prompt: generate only valid, complete
  Terraform HCL, no explanations or markdown fences, use variables for sensitive values,
  never hardcode credentials.
- `generate(system_prompt, user_prompt, temperature, max_tokens)` sends the request to
  either Together AI (OpenAI-compatible client) or local Ollama (raw HTTP to its
  OpenAI-compatible endpoint), depending on `USE_OLLAMA`.
- Includes retry-with-exponential-backoff (up to 5 attempts) for transient API errors, and
  `_strip_fences()` removes any ```` ``` ```` markdown fences the model adds despite
  instructions.
- `active_key_info()` returns a short string identifying the active backend/model for
  logging.

### 8.4 The Nine Experiment Scripts (`E01_*.py` – `E09_*.py`)

Each experiment script (`E01_ZeroShot.py` through `E09_ValidationRepair.py`) follows the
same overall shape, differing only in how the prompt sent to the LLM is constructed:

1. Load the fixed 300-prompt test set via `build_test_prompts()` and the reference module
   corpus via `load_modules()`.
2. For each of the 300 prompts, build an experiment-specific user prompt:
   - **E01**: the raw natural-language requirement only.
   - **E02**: adds a provider-specific instruction block (AWS/Azure/GCP resource
     prefixes).
   - **E03**: prepends 2–3 real TerraDS examples from the matching provider.
   - **E04/E05/E06/E07**: retrieve supporting examples via dense (ChromaDB), BM25, hybrid,
     or dependency-prioritised retrieval and prepend them as context.
   - **E08**: adds explicit security/compliance instructions (no open SSH, no public
     storage, no hardcoded secrets, least-privilege IAM).
   - **E09**: generates code, runs it through `evaluator.py`, and if issues are found,
     sends a second "repair" prompt containing the validation errors/warnings for one
     correction pass (both initial and repaired versions are kept).
3. Call `generate()` from `llm_client.py` with the constructed prompt.
4. Save the generated `.tf` file to that experiment's `E0X_*_generated/` directory (E09
   saves both initial and repaired versions, 600 files total).
5. Run `evaluate()` from `evaluator.py` on the generated code against the prompt's expected
   provider/resources and the reference corpus.
6. After all 300 samples, call `aggregate_results()` to average the per-sample metrics and
   `compute_final_score()` to produce the weighted composite score.
7. Write a per-experiment summary (`experiment_id`, `experiment_name`, `total_samples`,
   `aggregated` metrics, `final_score`, and the full per-sample `results`) to
   `results/E0X_*_results.json`.

### 8.5 Evaluation (`evaluator.py`)

Implements all ten offline metrics listed in Section 6: HCL syntax validity, `terraform fmt`
pass, `terraform validate` pass, provider correctness, resource coverage, dependency
correctness, security issue count, hardcoded-secret count, best-practice score, and code
similarity. `evaluate()` runs all checks for one generated file; `aggregate_results()`
averages these across the 300 samples of an experiment; `compute_final_score()` applies the
weighted composite formula from Section 7.

### 8.6 Orchestration and Reporting (`run_all_experiments.py`, `regenerate_table.py`)

- `run_all_experiments.py` imports all nine `E0X_*.py` modules and calls each one's `run()`
  function in order (or only the subset passed via `--only E01 E04 E09`). It collects each
  experiment's summary, builds a ranked comparison table (sorted by `final_score`,
  descending), and writes it to `results/final_comparison_table.json`,
  `.csv`, and `.txt`.
- `regenerate_table.py` rebuilds the same comparison table directly from the existing
  `results/E0X_*_results.json` files, without re-running any experiment — useful after
  changing `evaluator.py` or the scoring weights.
- `run_experiments_local.sh` is a convenience shell wrapper that installs dependencies and
  runs the full pipeline locally.

### 8.7 Output Layout

After a full run, each `E0X_*_generated/` directory contains the 300 generated `.tf` files
for that experiment (E09 contains 600: initial + repaired), and `results/` contains one JSON
file per experiment plus the combined `final_comparison_table.json/.csv/.txt`.

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
