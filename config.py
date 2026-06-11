"""
config.py
Shared configuration for all 9 Terraform generation experiments.
LJMU Thesis – AI-Driven Terraform Code Generation for Multi-Cloud Infrastructure
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env from the same folder as this file
load_dotenv(Path(__file__).parent / ".env")

# ── Together AI ────────────────────────────────────────────────────────────────
# Set TOGETHER_API_KEY in your .env file (see .env.example) — never hardcode keys here.
TOGETHER_API_KEY = os.environ.get("TOGETHER_API_KEY", "")
TOGETHER_MODEL   = "meta-llama/Llama-3.3-70B-Instruct-Turbo"

# Gemini (available for future use)
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")

# ── Backend selector ──────────────────────────────────────────────────────────
# Set USE_OLLAMA = True to run fully locally via Ollama (no rate limits, no API key).
# Ollama must be running: `ollama serve` and model pulled: `ollama pull llama3.3:70b`
USE_OLLAMA   = False
OLLAMA_URL   = "http://localhost:11434/v1/chat/completions"
OLLAMA_MODEL = "llama3.3:70b"

if not USE_OLLAMA and not TOGETHER_API_KEY:
    raise RuntimeError(
        "TOGETHER_API_KEY is not set. Copy .env.example to .env and add your key."
    )

# ── Paths ──────────────────────────────────────────────────────────────────────
DATASET_PATH = "/Users/suryadevarachetansai/Desktop/LJMU_Thesis/Data-Sets/14217386/TerraDS"
OUTPUT_DIR   = "/Users/suryadevarachetansai/Desktop/LJMU_Thesis/Coding/Code"

# ── Experiment settings ───────────────────────────────────────────────────────
NUM_SAMPLES = 300       # fixed test set size across all 9 experiments
RANDOM_SEED = 42

# ── ChromaDB (RAG experiments E04, E06, E07) ──────────────────────────────────
CHROMA_PERSIST_DIR = os.path.join(OUTPUT_DIR, "chroma_db")
CHROMA_COLLECTION  = "terrads_collection"

# ── Cloud providers ───────────────────────────────────────────────────────────
PROVIDERS = {
    "aws":     {"prefix": "aws_",     "label": "AWS"},
    "azurerm": {"prefix": "azurerm_", "label": "Azure"},
    "google":  {"prefix": "google_",  "label": "GCP"},
}

# ── Results directory ─────────────────────────────────────────────────────────
RESULTS_DIR = os.path.join(OUTPUT_DIR, "results")
os.makedirs(RESULTS_DIR,        exist_ok=True)
os.makedirs(CHROMA_PERSIST_DIR, exist_ok=True)
