"""
build_chroma_index.py
Extracts TerraDS .tar.gz archives until we have enough .tf modules
per provider, then builds (or rebuilds) the ChromaDB index.

Run once before E04 / E06 / E07:
    python3 build_chroma_index.py
"""

from __future__ import annotations
import os
import re
import tarfile
import random
import hashlib
from pathlib import Path
from tqdm import tqdm

# ── Config ────────────────────────────────────────────────────────────────────
DATASET_PATH   = "/Users/suryadevarachetansai/Desktop/LJMU_Thesis/Data-Sets/14217386/TerraDS"
EXTRACT_DIR    = os.path.join(DATASET_PATH, "extracted")
TARGET_PER_PROVIDER = 400          # modules needed per provider
RANDOM_SEED    = 42

PROVIDERS = {
    "aws":     "aws_",
    "azurerm": "azurerm_",
    "google":  "google_",
}

os.makedirs(EXTRACT_DIR, exist_ok=True)


# ── Helpers ───────────────────────────────────────────────────────────────────

def detect_provider(content: str) -> str | None:
    for provider, prefix in PROVIDERS.items():
        if re.search(rf'resource\s+"({prefix})', content):
            return provider
    return None


def count_tf_files() -> dict[str, int]:
    counts = {p: 0 for p in PROVIDERS}
    for tf_path in Path(EXTRACT_DIR).rglob("*.tf"):
        try:
            content = tf_path.read_text(errors="ignore")
        except Exception:
            continue
        provider = detect_provider(content)
        if provider:
            counts[provider] += 1
    return counts


# ── Step 1: Extract archives until we have enough modules ──────────────────

def extract_until_enough():
    archives = list(Path(DATASET_PATH).glob("*.tar.gz"))
    random.seed(RANDOM_SEED)
    random.shuffle(archives)

    print(f"Found {len(archives):,} archives in TerraDS.")
    print(f"Target: {TARGET_PER_PROVIDER} .tf modules per provider.\n")

    counts = count_tf_files()
    print(f"Already extracted: {counts}")

    for archive in tqdm(archives, desc="Extracting archives"):
        if all(v >= TARGET_PER_PROVIDER for v in counts.values()):
            print(f"\n✓ Target reached: {counts}")
            break

        try:
            with tarfile.open(archive, "r:gz") as tar:
                for member in tar.getmembers():
                    if member.name.endswith(".tf"):
                        out_path = Path(EXTRACT_DIR) / member.name
                        if not out_path.exists():
                            out_path.parent.mkdir(parents=True, exist_ok=True)
                            try:
                                f = tar.extractfile(member)
                                if f:
                                    content = f.read().decode(errors="ignore")
                                    provider = detect_provider(content)
                                    if provider and counts[provider] < TARGET_PER_PROVIDER:
                                        out_path.write_text(content)
                                        counts[provider] += 1
                            except Exception:
                                pass
        except Exception:
            continue

    print(f"\nFinal module counts: {counts}")
    return counts


# ── Step 2: Build ChromaDB index ──────────────────────────────────────────────

def build_index():
    import sys
    sys.path.insert(0, "/Users/suryadevarachetansai/Desktop/LJMU_Thesis/Coding/Code")

    import chromadb
    from chromadb.utils import embedding_functions
    from config import CHROMA_PERSIST_DIR, CHROMA_COLLECTION

    EMBED_MODEL = "all-MiniLM-L6-v2"

    print(f"\nBuilding ChromaDB index at: {CHROMA_PERSIST_DIR}")
    client = chromadb.PersistentClient(path=CHROMA_PERSIST_DIR)
    ef     = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=EMBED_MODEL)

    # Delete existing collection if present
    existing = [c.name for c in client.list_collections()]
    if CHROMA_COLLECTION in existing:
        print(f"  Deleting existing collection '{CHROMA_COLLECTION}' …")
        client.delete_collection(CHROMA_COLLECTION)

    collection = client.create_collection(name=CHROMA_COLLECTION, embedding_function=ef)

    # Gather all .tf files
    tf_files = list(Path(EXTRACT_DIR).rglob("*.tf"))
    print(f"  Found {len(tf_files)} .tf files to index.")

    docs, ids, metas = [], [], []
    for tf_path in tf_files:
        try:
            content = tf_path.read_text(errors="ignore")
        except Exception:
            continue
        if not content.strip():
            continue
        provider = detect_provider(content)
        if not provider:
            continue
        doc_id = hashlib.md5(content.encode()).hexdigest()
        resources = re.findall(r'resource\s+"([a-z_]+)"', content)
        docs.append(content[:2000])
        ids.append(doc_id)
        metas.append({
            "provider":  provider,
            "resources": ",".join(resources[:10]),
            "path":      str(tf_path),
        })

    # Deduplicate by id
    seen = set()
    unique_docs, unique_ids, unique_metas = [], [], []
    for d, i, m in zip(docs, ids, metas):
        if i not in seen:
            seen.add(i)
            unique_docs.append(d)
            unique_ids.append(i)
            unique_metas.append(m)

    print(f"  Indexing {len(unique_docs)} unique modules …")
    BATCH = 100
    for i in tqdm(range(0, len(unique_docs), BATCH), desc="  Indexing"):
        collection.add(
            documents=unique_docs[i:i+BATCH],
            ids=unique_ids[i:i+BATCH],
            metadatas=unique_metas[i:i+BATCH],
        )

    print(f"\n✓ ChromaDB index built: {len(unique_docs)} modules indexed.")
    by_provider = {}
    for m in unique_metas:
        by_provider[m["provider"]] = by_provider.get(m["provider"], 0) + 1
    for p, n in by_provider.items():
        print(f"   {p}: {n} modules")


# ── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    counts = extract_until_enough()

    total = sum(counts.values())
    if total == 0:
        print("\n✗ No .tf files found after extraction. Check DATASET_PATH.")
    else:
        build_index()
        print("\nDone. You can now run E04, E06, E07.")
