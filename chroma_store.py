"""
ChromaDB vector store builder for RAG experiments (E04, E06, E07).
Embeds TerraDS Terraform modules using sentence-transformers
and persists to disk so all RAG experiments share the same index.
"""

from __future__ import annotations
import os
import hashlib
from tqdm import tqdm

import chromadb
from chromadb.utils import embedding_functions

from config import CHROMA_PERSIST_DIR, CHROMA_COLLECTION
from dataset_loader import load_modules

# Use a lightweight local embedding model (no API needed)
EMBED_MODEL = "all-MiniLM-L6-v2"

_collection = None


def get_collection():
    """Return (or build) the ChromaDB collection."""
    global _collection
    if _collection is not None:
        return _collection

    client = chromadb.PersistentClient(path=CHROMA_PERSIST_DIR)
    ef     = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=EMBED_MODEL)

    existing = [c.name for c in client.list_collections()]
    if CHROMA_COLLECTION in existing:
        print(f"  ChromaDB: loading existing collection '{CHROMA_COLLECTION}'")
        _collection = client.get_collection(name=CHROMA_COLLECTION, embedding_function=ef)
        return _collection

    print(f"  ChromaDB: building collection '{CHROMA_COLLECTION}' …")
    _collection = client.create_collection(name=CHROMA_COLLECTION, embedding_function=ef)

    modules = load_modules()
    docs, ids, metas = [], [], []

    for provider, mods in modules.items():
        for mod in mods:
            content = mod["content"]
            # Use hash as stable ID
            doc_id = hashlib.md5(content.encode()).hexdigest()
            docs.append(content[:2000])          # ChromaDB doc (truncated)
            ids.append(doc_id)
            metas.append({
                "provider":  provider,
                "resources": ",".join(mod["resources"][:10]),
                "path":      mod["path"],
            })

    # Batch insert
    BATCH = 100
    for i in tqdm(range(0, len(docs), BATCH), desc="  Indexing TerraDS"):
        _collection.add(
            documents=docs[i:i+BATCH],
            ids=ids[i:i+BATCH],
            metadatas=metas[i:i+BATCH],
        )

    print(f"  ChromaDB: indexed {len(docs)} modules.")
    return _collection


def dense_retrieve(query: str, provider: str = None, top_k: int = 3) -> list[str]:
    """
    Semantic (dense) retrieval from ChromaDB.
    Optionally filter by provider.
    Returns list of HCL content strings.
    """
    col = get_collection()
    where = {"provider": provider} if provider and provider != "multi" else None
    results = col.query(
        query_texts=[query],
        n_results=top_k,
        where=where,
    )
    return results["documents"][0] if results["documents"] else []
