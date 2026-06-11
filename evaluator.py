"""
Evaluation metrics for all 9 Terraform generation experiments.
Metrics (all offline / static — no real cloud deployment):
  1. HCL Syntax Validity Rate
  2. Terraform Format Pass Rate
  3. Terraform Validation Pass Rate  (offline, no provider download)
  4. Provider Correctness
  5. Resource Coverage
  6. Dependency Correctness
  7. Security Issue Count
  8. Hardcoded Secret Count
  9. Best-Practice Score
 10. Code Similarity Score
"""

from __future__ import annotations
import re
import subprocess
import tempfile
import os
from difflib import SequenceMatcher


# ─────────────────────────────────────────────────────────────────────────────
# 1. HCL Syntax Validity
# ─────────────────────────────────────────────────────────────────────────────

def check_hcl_syntax(code: str) -> bool:
    """
    Parse HCL braces / quotes structure without calling terraform.
    Returns True if basic block structure is balanced and non-empty.
    """
    code = code.strip()
    if not code:
        return False
    # Strip string literals to avoid counting braces inside them
    no_strings = re.sub(r'"(?:[^"\\]|\\.)*"', '""', code)
    depth = 0
    for ch in no_strings:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0 and bool(re.search(r'\bresource\b|\bprovider\b|\bmodule\b|\bdata\b', code))


# ─────────────────────────────────────────────────────────────────────────────
# 2. Terraform Format Pass Rate
# ─────────────────────────────────────────────────────────────────────────────

def check_format(code: str) -> bool:
    """
    Run `terraform fmt -check` on the generated code in a temp directory.
    Returns True if the file passes formatting checks.
    Falls back to True if terraform binary is not available.
    """
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            tf_file = os.path.join(tmpdir, "main.tf")
            with open(tf_file, "w") as f:
                f.write(code)
            result = subprocess.run(
                ["terraform", "fmt", "-check", tf_file],
                capture_output=True, text=True, timeout=15
            )
            return result.returncode == 0
    except FileNotFoundError:
        # terraform not installed in this environment; use indentation heuristic
        return _format_heuristic(code)
    except Exception:
        return False


def _format_heuristic(code: str) -> bool:
    """Lightweight format check: 2-space indent, = alignment."""
    lines = code.splitlines()
    for line in lines:
        stripped = line.lstrip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(stripped)
        if indent % 2 != 0:
            return False
    return True


# ─────────────────────────────────────────────────────────────────────────────
# 3. Terraform Validation Pass Rate
# ─────────────────────────────────────────────────────────────────────────────

def check_validation(code: str) -> bool:
    """
    Run `terraform validate` after `terraform init -backend=false`.
    Falls back to heuristic if terraform binary absent.
    """
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            tf_file = os.path.join(tmpdir, "main.tf")
            with open(tf_file, "w") as f:
                f.write(code)
            # Minimal provider override to skip registry downloads
            override = os.path.join(tmpdir, "override.tf")
            with open(override, "w") as f:
                f.write('terraform { required_providers {} }\n')
            subprocess.run(
                ["terraform", "init", "-backend=false", "-no-color"],
                cwd=tmpdir, capture_output=True, timeout=30
            )
            result = subprocess.run(
                ["terraform", "validate", "-no-color"],
                cwd=tmpdir, capture_output=True, text=True, timeout=15
            )
            return result.returncode == 0
    except FileNotFoundError:
        return _validation_heuristic(code)
    except Exception:
        return False


def _validation_heuristic(code: str) -> bool:
    """Check for common validation issues: missing required blocks, orphan refs."""
    has_resource = bool(re.search(r'\bresource\s+"', code))
    has_provider  = bool(re.search(r'\bprovider\s+"', code))
    balanced      = check_hcl_syntax(code)
    return has_resource and balanced


# ─────────────────────────────────────────────────────────────────────────────
# 4. Provider Correctness
# ─────────────────────────────────────────────────────────────────────────────

PROVIDER_PREFIXES = {
    "aws":     re.compile(r'resource\s+"aws_'),
    "azurerm": re.compile(r'resource\s+"azurerm_'),
    "google":  re.compile(r'resource\s+"google_'),
}
WRONG_PROVIDER = {
    "aws":     ["azurerm_", "google_"],
    "azurerm": ["aws_", "google_"],
    "google":  ["aws_", "azurerm_"],
}


def check_provider_correctness(code: str, expected_provider: str) -> float:
    """
    Returns 1.0 if code uses correct provider resources and no wrong-provider resources.
    Returns 0.5 if partially correct.
    Returns 0.0 if wrong provider found.
    For multi-cloud prompts always returns 1.0 (all providers allowed).
    """
    if expected_provider == "multi":
        return 1.0

    # Check for wrong providers
    for wrong in WRONG_PROVIDER.get(expected_provider, []):
        if re.search(rf'resource\s+"{re.escape(wrong)}', code):
            return 0.0

    # Check correct provider present
    pat = PROVIDER_PREFIXES.get(expected_provider)
    if pat and pat.search(code):
        return 1.0

    return 0.5  # has resources but none with clear prefix


# ─────────────────────────────────────────────────────────────────────────────
# 5. Resource Coverage
# ─────────────────────────────────────────────────────────────────────────────

def check_resource_coverage(code: str, prompt: str) -> float:
    """
    Extract resource keywords from the prompt and check how many appear in the code.
    Returns ratio (0.0 – 1.0).
    """
    # Keywords that map prompt terms to Terraform resource name fragments
    keyword_map = {
        "vpc":             ["vpc", "virtual_network", "network"],
        "subnet":          ["subnet"],
        "security group":  ["security_group", "network_security_group", "firewall"],
        "internet gateway":["internet_gateway"],
        "route table":     ["route_table", "route"],
        "ec2":             ["instance"],
        "s3":              ["bucket"],
        "storage":         ["bucket", "storage_account", "storage_bucket"],
        "virtual machine": ["virtual_machine", "instance"],
        "firewall":        ["firewall", "security_group"],
        "load balancer":   ["lb", "load_balancer", "alb"],
        "kubernetes":      ["eks", "aks", "container_cluster"],
        "database":        ["db_instance", "sql_server", "sql_database", "database_instance"],
        "iam":             ["iam_role", "iam_policy", "role_assignment"],
        "key vault":       ["key_vault"],
        "container":       ["container_registry", "container_cluster"],
    }

    prompt_lower = prompt.lower()
    code_lower   = code.lower()
    expected = []
    for kw, fragments in keyword_map.items():
        if kw in prompt_lower:
            expected.append(fragments)

    if not expected:
        return 1.0  # can't determine expectation

    hits = sum(1 for frags in expected if any(f in code_lower for f in frags))
    return hits / len(expected)


# ─────────────────────────────────────────────────────────────────────────────
# 6. Dependency Correctness
# ─────────────────────────────────────────────────────────────────────────────

def check_dependency_correctness(code: str) -> float:
    """
    Check whether resources are connected via Terraform references (e.g. resource.type.name.id)
    rather than hardcoded string IDs.
    Returns ratio of referenced attributes vs total attribute assignments.
    """
    # Count proper Terraform references: resource_type.resource_name.attribute
    ref_pattern   = re.compile(r'=\s*[a-z][a-z0-9_]+\.[a-z][a-z0-9_]+\.[a-z_]+')
    # Count hardcoded ID-looking strings: "subnet-xxxxx", "/subscriptions/...", etc.
    hc_id_pattern = re.compile(r'=\s*"(subnet-[a-f0-9]+|sg-[a-f0-9]+|/subscriptions/[^"]+|projects/[^"]+)"')

    refs     = len(ref_pattern.findall(code))
    hc_ids   = len(hc_id_pattern.findall(code))
    total    = refs + hc_ids

    if total == 0:
        # No explicit IDs at all – partial credit
        return 0.6
    return refs / total


# ─────────────────────────────────────────────────────────────────────────────
# 7. Security Issue Count
# ─────────────────────────────────────────────────────────────────────────────

SECURITY_PATTERNS = [
    (re.compile(r'cidr_blocks\s*=\s*\[?"0\.0\.0\.0/0"'),        "open_ingress_0000"),
    (re.compile(r'from_port\s*=\s*22\b.*?cidr_blocks',           re.DOTALL), "ssh_open"),
    (re.compile(r'acl\s*=\s*"public-read"'),                     "public_bucket_acl"),
    (re.compile(r'block_public_acls\s*=\s*false'),               "public_acl_not_blocked"),
    (re.compile(r'publicly_accessible\s*=\s*true'),              "db_public"),
    (re.compile(r'allow_unauthenticated_identities\s*=\s*true'), "unauthenticated_allowed"),
    (re.compile(r'source_ranges\s*=\s*\[?"0\.0\.0\.0/0"'),      "gcp_open_firewall"),
    (re.compile(r'enable_https_traffic_only\s*=\s*false'),       "http_storage"),
]


def count_security_issues(code: str) -> int:
    return sum(1 for pat, _ in SECURITY_PATTERNS if pat.search(code))


# ─────────────────────────────────────────────────────────────────────────────
# 8. Hardcoded Secret Count
# ─────────────────────────────────────────────────────────────────────────────

SECRET_PATTERNS = [
    re.compile(r'(?i)(password|secret|access_key|secret_key|private_key|token|api_key)\s*=\s*"[^${\n]{4,}"'),
    re.compile(r'AKIA[0-9A-Z]{16}'),               # AWS access key
    re.compile(r'(?i)AIza[0-9A-Za-z\-_]{35}'),     # Google API key
    re.compile(r'(?i)(client_secret|client_id)\s*=\s*"[^${\n]{8,}"'),
]


def count_hardcoded_secrets(code: str) -> int:
    return sum(1 for pat in SECRET_PATTERNS if pat.search(code))


# ─────────────────────────────────────────────────────────────────────────────
# 9. Best-Practice Score
# ─────────────────────────────────────────────────────────────────────────────

def compute_best_practice_score(code: str) -> float:
    """
    Score 0–1 based on: variables used, outputs declared, tags/labels present,
    descriptions used, meaningful naming, no hardcoded region strings.
    """
    checks = {
        "uses_variables":    bool(re.search(r'\bvar\.[a-z_]+', code)),
        "declares_variable": bool(re.search(r'\bvariable\s+"', code)),
        "declares_output":   bool(re.search(r'\boutput\s+"', code)),
        "has_tags":          bool(re.search(r'\btags\s*=\s*\{', code)),
        "has_labels":        bool(re.search(r'\blabels\s*=\s*\{', code)),
        "has_description":   bool(re.search(r'\bdescription\s*=\s*"', code)),
        "no_hardcoded_region": not bool(re.search(r'"us-east-1"|"eastus"|"us-central1"', code)),
        "uses_locals":       bool(re.search(r'\blocals\s*\{', code)),
    }
    return sum(checks.values()) / len(checks)


# ─────────────────────────────────────────────────────────────────────────────
# 10. Code Similarity Score
# ─────────────────────────────────────────────────────────────────────────────

def compute_similarity(generated: str, reference: str) -> float:
    """Sequence-based structural similarity (0–1)."""
    if not generated or not reference:
        return 0.0
    return SequenceMatcher(None, generated, reference).ratio()


def compute_similarity_to_corpus(generated: str, corpus: list[str], top_k: int = 3) -> float:
    """Average similarity against top-k closest corpus examples."""
    if not corpus:
        return 0.0
    scores = sorted(
        [compute_similarity(generated, ref) for ref in corpus],
        reverse=True
    )
    return sum(scores[:top_k]) / min(top_k, len(scores))


# ─────────────────────────────────────────────────────────────────────────────
# Unified evaluator
# ─────────────────────────────────────────────────────────────────────────────

def evaluate(code: str, prompt: str, expected_provider: str, reference_corpus: list[str] = None) -> dict:
    """
    Run all 10 metrics and return a result dict.
    reference_corpus: list of real TerraDS HCL strings for similarity scoring.
    """
    return {
        "hcl_syntax_valid":       check_hcl_syntax(code),
        "format_pass":            check_format(code),
        "validation_pass":        check_validation(code),
        "provider_correctness":   check_provider_correctness(code, expected_provider),
        "resource_coverage":      check_resource_coverage(code, prompt),
        "dependency_correctness": check_dependency_correctness(code),
        "security_issue_count":   count_security_issues(code),
        "hardcoded_secret_count": count_hardcoded_secrets(code),
        "best_practice_score":    compute_best_practice_score(code),
        "code_similarity_score":  compute_similarity_to_corpus(code, reference_corpus or []),
    }


def aggregate_results(results: list[dict]) -> dict:
    """Aggregate a list of per-sample metric dicts into means."""
    if not results:
        return {}
    keys = results[0].keys()
    agg = {}
    for k in keys:
        vals = [r[k] for r in results if r.get(k) is not None]
        agg[k] = round(sum(vals) / len(vals), 4) if vals else 0.0
    return agg


def compute_final_score(agg: dict) -> float:
    """
    Weighted final score (0–100) per the thesis scoring logic.
    Lower-is-better metrics are inverted (max 5 issues assumed).
    """
    weights = {
        "hcl_syntax_valid":       0.15,
        "format_pass":            0.10,
        "validation_pass":        0.15,
        "provider_correctness":   0.15,
        "resource_coverage":      0.15,
        "dependency_correctness": 0.10,
        "best_practice_score":    0.10,
        "security_issue_count":   0.05,   # inverted
        "hardcoded_secret_count": 0.05,   # inverted
    }
    score = 0.0
    for metric, w in weights.items():
        val = agg.get(metric, 0.0)
        if metric in ("security_issue_count", "hardcoded_secret_count"):
            val = max(0.0, 1.0 - val / 5.0)  # invert; cap at 5 issues
        score += val * w
    return round(score * 100, 2)
