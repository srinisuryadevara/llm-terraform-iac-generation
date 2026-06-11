#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# LJMU Thesis – Run All 9 Terraform Generation Experiments (300 samples each)
# Usage:  bash run_experiments_local.sh
#         bash run_experiments_local.sh --only E01 E04   # run specific ones
# ──────────────────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  LJMU Thesis – Terraform Generation Experiments"
echo "  Directory : $SCRIPT_DIR"
echo "══════════════════════════════════════════════════════════════"

# ── 1. Check Python ──────────────────────────────────────────────────────────
PYTHON=$(command -v python3 || command -v python)
if [ -z "$PYTHON" ]; then
  echo "❌  Python 3 not found. Install from https://python.org"
  exit 1
fi
echo "✔  Python : $($PYTHON --version)"

# ── 2. Install / upgrade dependencies ────────────────────────────────────────
echo ""
echo "── Installing dependencies ──────────────────────────────────"
$PYTHON -m pip install --upgrade --quiet \
  "openai>=1.0.0" \
  "chromadb>=0.5.0" \
  "sentence-transformers>=2.7.0" \
  "python-dotenv>=1.0.0" \
  "tqdm>=4.66.0" \
  "pandas>=2.0.0"
echo "✔  Dependencies installed"

# ── 3. Check for .env / API key ───────────────────────────────────────────────
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "❌  .env not found. Run: cp .env.example .env   then add your TOGETHER_API_KEY"
  exit 1
fi

# ── 4. Create results directory ───────────────────────────────────────────────
mkdir -p "$SCRIPT_DIR/results"

# ── 5. Run experiments ────────────────────────────────────────────────────────
echo ""
echo "── Starting experiments ─────────────────────────────────────"
echo "   Samples  : 300 per experiment"
echo "   Model    : LLaMA 3.3 70B via Together AI"
echo "   Output   : $SCRIPT_DIR/results/"
echo ""

LOG_FILE="$SCRIPT_DIR/results/run_$(date +%Y%m%d_%H%M%S).log"

# Pass through any --only flags the user gave
$PYTHON run_all_experiments.py "$@" 2>&1 | tee "$LOG_FILE"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Done! Results saved to:"
echo "    $SCRIPT_DIR/results/"
echo "  Full log:"
echo "    $LOG_FILE"
echo "══════════════════════════════════════════════════════════════"
