import json
import os
from pathlib import Path
import pickle
import numpy as np
from sentence_transformers import SentenceTransformer
from tqdm import tqdm

# Paths
BASE_FOLDER = Path("backend")
RAW_JSON_FOLDER = BASE_FOLDER / "raw_json"
DATA_FOLDER = BASE_FOLDER / "data"
INDEX_FOLDER = BASE_FOLDER / "indexes"

# Languages and laws
LANGUAGES = ["en", "hi", "ne"]
LAWS = ["BNS", "BNSS", "BSA"]

# Embedding model (multilingual: English, Hindi, Nepali) - as per architecture
EMBEDDING_MODEL = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
model = SentenceTransformer(EMBEDDING_MODEL)

def load_json_files(folder: Path):
    """Load all JSON files from a folder."""
    documents = []
    if not folder.exists():
        return documents
    for file_path in folder.glob("*.json"):
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    documents.extend(data)
                elif isinstance(data, dict):
                    documents.append(data)
                else:
                    print(f"Warning: Unsupported JSON structure in {file_path}")
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
    return documents

def save_jsonl(documents, output_file: Path):
    """Save documents to JSONL."""
    output_file.parent.mkdir(parents=True, exist_ok=True)
    try:
        with open(output_file, "w", encoding="utf-8") as f:
            for doc in documents:
                f.write(json.dumps(doc, ensure_ascii=False) + "\n")
    except Exception as e:
        print(f"Error writing JSONL {output_file}: {e}")

def generate_embeddings(documents):
    """Generate embeddings for documents."""
    embeddings = []
    texts = []
    meta = []

    for doc in tqdm(documents, desc="Generating embeddings"):
        try:
            text = doc.get("content") or doc.get("text") or str(doc)
            emb = model.encode(text)
            embeddings.append(emb)
            texts.append(text)
            meta.append(doc)
        except Exception as e:
            print(f"Error embedding document: {e}")
    
    embeddings = np.array(embeddings)
    return embeddings, texts, meta

def process_law(lang: str, law: str):
    """Process a single law for a single language."""
    print(f"\nProcessing {lang}/{law}...")

    # Raw JSON folder for this law
    raw_folder = RAW_JSON_FOLDER / lang / law
    documents = load_json_files(raw_folder)
    if not documents:
        print(f"No documents found for {lang}/{law}. Skipping.")
        return

    # Save JSONL
    jsonl_output = DATA_FOLDER / lang / law / f"{law}.jsonl"
    save_jsonl(documents, jsonl_output)
    print(f"Saved JSONL: {jsonl_output}")

    # Generate embeddings
    embeddings, texts, meta = generate_embeddings(documents)

    # Save vector store files
    index_folder = INDEX_FOLDER / lang / law
    index_folder.mkdir(parents=True, exist_ok=True)

    np.save(index_folder / "embeddings.npy", embeddings)
    with open(index_folder / "texts.pkl", "wb") as f:
        pickle.dump(texts, f)
    with open(index_folder / "meta.pkl", "wb") as f:
        pickle.dump(meta, f)

    print(f"Saved embeddings in: {index_folder}")

def main():
    for lang in LANGUAGES:
        for law in LAWS:
            process_law(lang, law)
    print("\nAll JSONL and embeddings generation completed.")

if __name__ == "__main__":
    main()
