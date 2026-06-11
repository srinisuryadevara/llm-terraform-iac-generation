"""
llm_client.py
LLM client supporting two backends:
  • Together AI (default) – cloud inference via OpenAI-compatible API
  • Ollama (local)        – no rate limits; set USE_OLLAMA=True in config.py

Together AI uses the openai package pointed at https://api.together.ai/v1
"""

import time
import json
import logging
import urllib.request
import urllib.error

from openai import OpenAI

from config import TOGETHER_API_KEY, TOGETHER_MODEL, USE_OLLAMA, OLLAMA_URL, OLLAMA_MODEL

# ── Logging ────────────────────────────────────────────────────────────────────
logging.basicConfig(
    format="%(asctime)s [llm_client] %(levelname)s %(message)s",
    level=logging.INFO,
)
log = logging.getLogger("llm_client")

# ── Constants ──────────────────────────────────────────────────────────────────
MAX_RETRIES    = 5
RETRY_BACKOFF  = 2.0

# ── Together AI client ─────────────────────────────────────────────────────────
_together_client = OpenAI(
    api_key=TOGETHER_API_KEY,
    base_url="https://api.together.ai/v1",
)

# ── System prompt shared by all experiments ────────────────────────────────────
SYSTEM_TERRAFORM = (
    "You are an expert Terraform Infrastructure-as-Code engineer. "
    "Generate only valid, complete Terraform HCL code. "
    "Do not include any explanation, markdown, or text outside the HCL code block. "
    "Use variables for sensitive values. Never hardcode credentials, passwords, or API keys."
)


def _strip_fences(text: str) -> str:
    """Remove markdown code fences the model sometimes wraps output in."""
    import re
    text = re.sub(r"^```[a-zA-Z]*\n?", "", text, flags=re.MULTILINE)
    text = re.sub(r"\n?```$",          "", text, flags=re.MULTILINE)
    return text.strip()


# ── Together AI backend ────────────────────────────────────────────────────────

def _generate_together(
    system_prompt: str,
    user_prompt:   str,
    temperature:   float = 0.2,
    max_tokens:    int   = 2048,
) -> str:
    """Call LLaMA 3.3 70B via Together AI using the openai package."""
    backoff = RETRY_BACKOFF
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = _together_client.chat.completions.create(
                model=TOGETHER_MODEL,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user",   "content": user_prompt},
                ],
                temperature=temperature,
                max_tokens=max_tokens,
            )
            text = response.choices[0].message.content.strip()
            return _strip_fences(text)
        except Exception as e:
            if attempt >= MAX_RETRIES:
                raise RuntimeError(
                    f"Together AI call failed after {MAX_RETRIES} attempts: {e}"
                ) from e
            log.warning("Together AI error (%s) – retrying in %.0fs …", e, backoff)
            time.sleep(backoff)
            backoff *= 2


# ── Ollama backend ─────────────────────────────────────────────────────────────

def _generate_ollama(
    system_prompt: str,
    user_prompt:   str,
    temperature:   float = 0.2,
    max_tokens:    int   = 2048,
) -> str:
    """Call LLaMA 3.3 70B via local Ollama (OpenAI-compatible endpoint)."""
    payload = json.dumps({
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": user_prompt},
        ],
        "temperature": temperature,
        "max_tokens":  max_tokens,
        "stream": False,
    }).encode()

    backoff = RETRY_BACKOFF
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            req = urllib.request.Request(
                OLLAMA_URL,
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=300) as resp:
                data = json.loads(resp.read().decode())
            text = data["choices"][0]["message"]["content"].strip()
            return _strip_fences(text)
        except Exception as e:
            if attempt >= MAX_RETRIES:
                raise RuntimeError(f"Ollama call failed after {MAX_RETRIES} attempts: {e}") from e
            log.warning("Ollama error (%s) – retrying in %.0fs …", e, backoff)
            time.sleep(backoff)
            backoff *= 2


# ── Public API ─────────────────────────────────────────────────────────────────

def generate(
    system_prompt: str,
    user_prompt:   str,
    temperature:   float = 0.2,
    max_tokens:    int   = 2048,
) -> str:
    """
    Call LLaMA 3.3 70B via Together AI (or Ollama if USE_OLLAMA=True).

    Args:
        system_prompt : Role / instruction for the model.
        user_prompt   : The actual user request.
        temperature   : Sampling temperature (default 0.2 for deterministic code).
        max_tokens    : Maximum tokens in the response.

    Returns:
        Generated text with markdown fences stripped.

    Raises:
        RuntimeError if all retry attempts fail.
    """
    if USE_OLLAMA:
        return _generate_ollama(system_prompt, user_prompt, temperature, max_tokens)
    return _generate_together(system_prompt, user_prompt, temperature, max_tokens)


def active_key_info() -> str:
    """Return a short string identifying the active backend (for logging)."""
    if USE_OLLAMA:
        return f"ollama/{OLLAMA_MODEL}"
    return f"together/{TOGETHER_MODEL} key=...{TOGETHER_API_KEY[-6:]}"
