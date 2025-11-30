from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from pydantic import BaseModel
from typing import Dict, List, Any, Tuple
from pathlib import Path
import pickle
import uvicorn
import logging
import asyncio
from collections import OrderedDict

try:
    from sentence_transformers import SentenceTransformer
    from sklearn.metrics.pairwise import cosine_similarity
except ImportError:
    SentenceTransformer = None

try:
    from transformers import pipeline, AutoTokenizer, AutoModelForQuestionAnswering
except ImportError:
    pipeline = None
    AutoTokenizer = None
    AutoModelForQuestionAnswering = None

try:
    from googletrans import Translator
except ImportError:
    Translator = None

try:
    from sentence_transformers import CrossEncoder
except ImportError:
    CrossEncoder = None

import numpy as np
import re
import time
from typing import Optional

try:
    import torch
except ImportError:
    torch = None

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# -----------------------
# App and CORS
# -----------------------
app = FastAPI(title="Legal Advisor Backend", version="0.2.0")
app.add_middleware(GZipMiddleware, minimum_size=1000)  # Compress responses > 1KB
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------
# Config
# -----------------------
ROOT = Path(__file__).resolve().parent
INDEX_DIR = ROOT / "indexes"
SUPPORTED_LANGS = {"en", "hi", "ne"}

DATASETS = ["BNS", "BSA", "BNSS"]

# Dataset full names for better display
DATASET_NAMES = {
    "BNS": "Bharatiya Nyaya Sanhita",
    "BSA": "Bharatiya Sakshya Adhiniyam",
    "BNSS": "Bharatiya Nagarik Suraksha Sanhita"
}

# -----------------------
# Models
# -----------------------
class ChatRequest(BaseModel):
    query: str
    language: str  # "en" | "hi" | "ne"

class LanguageChangeRequest(BaseModel):
    language: str  # "en" | "hi" | "ne"

class SearchResponse(BaseModel):
    language: str
    title: str
    explanation: str
    penalties: List[str]
    references: List[Dict[str, Any]]
    disclaimer: str
    source_code: str  # BNS, BSA, or BNSS
    source_name: str  # Full name of the legal code

# -----------------------
# In-memory index cache
# -----------------------
_indexes: Dict[str, Dict[str, Any]] = {}

# Global models - upgraded to multilingual with GPU support
_sentence_model = None
_qa_pipeline = None
_translator = None

# Enhanced query result cache with LRU eviction (max 200 entries)
_query_cache: OrderedDict = OrderedDict()
MAX_CACHE_SIZE = 200

# Query embedding cache with LRU eviction (max 500 entries, 15min TTL)
_embedding_cache: OrderedDict = OrderedDict()
MAX_EMBEDDING_CACHE_SIZE = 500
EMBEDDING_CACHE_TTL = 900  # 15 minutes

    # Optimized thresholds for better performance and accuracy
SIMILARITY_THRESHOLD = 0.3  # Lowered for better recall and fewer "no results" responses
QA_CONFIDENCE_THRESHOLD = 0.45  # Increased for better answer quality
TOP_K_RETRIEVAL = 3  # Reduced for faster processing

# Simple query patterns that don't need heavy processing
SIMPLE_GREETINGS = {
    'hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening',
    'नमस्ते', 'नमस्कार', 'प्रणाम', 'नमश्कार',  # Hindi
    'नमस्ते', 'नमस्कार', 'प्रणाम', 'नमश्कार',  # Nepali (same as Hindi)
    'bye', 'goodbye', 'see you', 'thank you', 'thanks',
    'धन्यवाद', 'शुक्रिया', 'अलविदा',  # Hindi
    'धन्यवाद', 'शुक्रिया', 'अलविदा',  # Nepali
}


async def _ensure_models_available_async():
    """Async version: Load multilingual models optimized for Hindi and Nepali - with GPU support"""
    global _sentence_model, _qa_pipeline, _translator

    if SentenceTransformer is None or pipeline is None or AutoTokenizer is None or AutoModelForQuestionAnswering is None:
        raise HTTPException(status_code=500, detail="Required ML libraries not installed. Please install sentence-transformers and transformers.")

    if _sentence_model is None:
        # Use architecture-specified model for better performance with GPU support
        logger.info("Loading multilingual sentence transformer with GPU support...")
        # Run in thread pool to avoid blocking
        _sentence_model = await asyncio.get_event_loop().run_in_executor(
            None, lambda: SentenceTransformer('sentence-transformers/paraphrase-multilingual-mpnet-base-v2', device='cuda' if torch.cuda.is_available() else 'cpu')
        )
        logger.info("Sentence transformer loaded successfully")

    if _qa_pipeline is None:
        # Use RoBERTa QA model for better multilingual support
        logger.info("Loading RoBERTa QA pipeline for multilingual support...")
        model_name = "deepset/roberta-base-squad2"
        _qa_pipeline = await asyncio.get_event_loop().run_in_executor(
            None, lambda: pipeline("question-answering", model=model_name, device='cuda' if torch.cuda.is_available() else 'cpu')
        )
        logger.info("QA pipeline loaded successfully")

    if _translator is None and Translator is not None:
        # Initialize translator for Hindi/Nepali queries
        logger.info("Initializing Google Translator...")
        _translator = Translator()
        logger.info("Translator initialized successfully")


def _ensure_models_available():
    """Load multilingual models optimized for Hindi and Nepali - with proper caching"""
    global _sentence_model, _qa_pipeline
    if SentenceTransformer is None or pipeline is None or AutoTokenizer is None or AutoModelForQuestionAnswering is None:
        raise HTTPException(status_code=500, detail="Required ML libraries not installed. Please install sentence-transformers and transformers.")

    if _sentence_model is None:
        # Use architecture-specified model for better performance
        logger.info("Loading sentence transformer as per architecture...")
        _sentence_model = SentenceTransformer('sentence-transformers/paraphrase-multilingual-mpnet-base-v2')
        logger.info("Sentence transformer loaded successfully")

    if _qa_pipeline is None:
        # Use RoBERTa QA model for better multilingual support
        logger.info("Loading RoBERTa QA pipeline for multilingual support...")
        model_name = "deepset/roberta-base-squad2"
        _qa_pipeline = pipeline("question-answering", model=model_name)
        logger.info("QA pipeline loaded successfully")


def _is_simple_query(query: str) -> bool:
    """Check if query is a simple greeting or non-legal question"""
    query_lower = query.lower().strip()
    return query_lower in SIMPLE_GREETINGS or len(query.split()) <= 2


def _get_cache_key(query: str, lang: str) -> str:
    """Generate cache key for query"""
    return f"{lang}:{query.lower().strip()}"


def _get_cached_embedding(query: str, lang: str) -> Optional[np.ndarray]:
    """Get cached query embedding if available and not expired"""
    cache_key = f"emb:{lang}:{query.lower().strip()}"
    if cache_key in _embedding_cache:
        cached = _embedding_cache[cache_key]
        if time.time() - cached.get('timestamp', 0) < EMBEDDING_CACHE_TTL:
            logger.info(f"Embedding cache hit for query: {cache_key}")
            _embedding_cache.move_to_end(cache_key)
            return cached['embedding']
        else:
            del _embedding_cache[cache_key]
    return None


def _cache_embedding(query: str, lang: str, embedding: np.ndarray):
    """Cache query embedding with timestamp and LRU eviction"""
    cache_key = f"emb:{lang}:{query.lower().strip()}"
    _embedding_cache[cache_key] = {
        'embedding': embedding,
        'timestamp': time.time()
    }
    _embedding_cache.move_to_end(cache_key)

    if len(_embedding_cache) > MAX_EMBEDDING_CACHE_SIZE:
        _embedding_cache.popitem(last=False)


def _get_cached_response(cache_key: str) -> Optional[Dict[str, Any]]:
    """Get cached response if available and not expired - with LRU eviction"""
    if cache_key in _query_cache:
        cached = _query_cache[cache_key]
        # Simple TTL check (5 minutes)
        if time.time() - cached.get('timestamp', 0) < 300:
            logger.info(f"Cache hit for query: {cache_key}")
            # Move to end (most recently used)
            _query_cache.move_to_end(cache_key)
            return cached['response']
        else:
            # Remove expired cache entry
            del _query_cache[cache_key]
    return None


def _cache_response(cache_key: str, response: Dict[str, Any]):
    """Cache response with timestamp and LRU eviction"""
    _query_cache[cache_key] = {
        'response': response,
        'timestamp': time.time()
    }
    # Move to end (most recently used)
    _query_cache.move_to_end(cache_key)

    # Limit cache size to prevent memory issues (LRU eviction)
    if len(_query_cache) > MAX_CACHE_SIZE:
        # Remove least recently used entry
        _query_cache.popitem(last=False)


def _cleanup_expired_cache():
    """Periodic cleanup of expired cache entries"""
    current_time = time.time()
    expired_keys = [
        key for key, value in _query_cache.items()
        if current_time - value.get('timestamp', 0) >= 300
    ]
    for key in expired_keys:
        del _query_cache[key]
    if expired_keys:
        logger.info(f"Cleaned up {len(expired_keys)} expired cache entries")


async def _preload_models_async():
    """Async preload models on startup to avoid delays"""
    await _ensure_models_available_async()


def _preload_models():
    """Preload models on first request to avoid delays"""
    _ensure_models_available()


def _preload_common_indexes():
    """Preload frequently used indexes on startup for all supported languages"""
    try:
        for lang in SUPPORTED_LANGS:
            logger.info(f"Preloading common indexes for language: {lang} ...")
            for dataset in DATASETS:
                try:
                    _load_index(lang, dataset)
                    logger.info(f"Successfully preloaded {lang} {dataset} index")
                except Exception as e:
                    logger.warning(f"Failed to preload index for {lang} / {dataset}: {e}")
    except Exception as e:
        logger.warning(f"Failed to preload indexes: {e}")


def _load_index(lang: str, dataset: str = "BNS"):
    """Lazy-load semantic embeddings artifacts for a language and dataset."""
    key = f"{lang}_{dataset}"
    if key in _indexes:
        return

    lang_dir = INDEX_DIR / lang / dataset
    if not lang_dir.exists():
        raise HTTPException(status_code=400, detail=f"Language index not found: {lang} dataset: {dataset}")

    try:
        with open(lang_dir / "texts.pkl", "rb") as f:
            texts = pickle.load(f)
        with open(lang_dir / "meta.pkl", "rb") as f:
            metas = pickle.load(f)
        embeddings = np.load(lang_dir / "embeddings.npy")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load index artifacts for {lang} dataset {dataset}: {e}")

    _ensure_models_available()

    _indexes[key] = {
        "embeddings": embeddings,
        "texts": texts,
        "metas": metas,
    }


def _extract_text_from_meta(meta: Dict) -> str:
    """Extract actual text content from metadata for QA context"""
    if not meta or 'sections' not in meta:
        return ""

    texts = []
    for section in meta['sections']:
        if 'text' in section and section['text']:
            texts.append(section['text'])

    return ' '.join(texts)


async def _extract_answer_from_multiple_docs_async(question: str, docs: List[str], metas: List[Dict], lang: str) -> Dict[str, Any]:
    """Async version: Extract answer from multiple documents with validation - optimized for performance and quality"""
    logger.info(f"Extracting answer for question: '{question}' from {len(metas)} documents")

    # Use top 2 documents for better performance
    if not metas:
        logger.warning("No metadata provided for answer extraction")
        return {
            'answer': "No relevant information found.",
            'confidence': 0.0,
            'doc_index': 0,
            'meta': {},
            'context': ""
        }

    # Process up to 2 documents asynchronously
    tasks = []
    for i in range(min(2, len(metas))):
        meta = metas[i]
        qa_context = _extract_text_from_meta(meta)

        # Skip if no text content
        if not qa_context.strip():
            logger.warning(f"Document {i}: No text content found in metadata")
            continue

        # Use optimized context length for better performance
        qa_context = qa_context[:1200]
        logger.debug(f"Document {i}: Context length {len(qa_context)}, first 100 chars: {qa_context[:100]}")

        # Create async task for QA processing
        task = asyncio.get_event_loop().run_in_executor(
            None, _process_qa_for_doc, question, qa_context, i, meta
        )
        tasks.append(task)

    # Wait for all QA tasks to complete
    qa_results = await asyncio.gather(*tasks, return_exceptions=True)

    answers = []
    for result in qa_results:
        if isinstance(result, Exception):
            logger.warning(f"QA task failed: {result}")
            continue

        if result and result['confidence'] >= QA_CONFIDENCE_THRESHOLD and len(result['answer']) > 3:
            answers.append(result)
        else:
            logger.warning(f"Answer rejected - confidence {result['confidence']:.3f} < {QA_CONFIDENCE_THRESHOLD} or answer too short")

    if answers:
        # Sort by confidence and return best answer
        answers.sort(key=lambda x: x['confidence'], reverse=True)
        best_answer = answers[0]
        logger.info(f"Selected best answer from doc {best_answer['doc_index']} with confidence {best_answer['confidence']:.3f}")
        return best_answer
    else:
        # Fallback to first document snippet
        logger.warning("No valid answers found, using fallback from first document")
        meta = metas[0]
        qa_context = _extract_text_from_meta(meta)
        return {
            'answer': qa_context[:600] + "..." if len(qa_context) > 600 else qa_context,
            'confidence': 0.0,
            'doc_index': 0,
            'meta': meta,
            'context': qa_context
        }


def _process_qa_for_doc(question: str, qa_context: str, doc_index: int, meta: Dict) -> Dict[str, Any]:
    """Process QA for a single document"""
    try:
        qa_result = _qa_pipeline(question=question, context=qa_context)
        answer = qa_result['answer'].strip()
        confidence = qa_result['score']

        logger.info(f"Document {doc_index}: QA result - answer: '{answer[:50]}...', confidence: {confidence:.3f}")

        return {
            'answer': answer,
            'confidence': confidence,
            'doc_index': doc_index,
            'meta': meta,
            'context': qa_context[:300] + "..." if len(qa_context) > 300 else qa_context
        }
    except Exception as e:
        logger.warning(f"QA failed for doc {doc_index}: {e}")
        return None


def _extract_answer_from_multiple_docs_old(question: str, docs: List[str], metas: List[Dict], lang: str) -> Dict[str, Any]:
    """Extract answer from multiple documents with validation"""
    answers = []

    for i, (doc_text, meta) in enumerate(zip(docs, metas)):
        try:
            # Extract actual text content from metadata for QA context
            qa_context = _extract_text_from_meta(meta)

            # Skip if no text content
            if not qa_context.strip():
                continue

            # Get QA result for this document
            qa_result = _qa_pipeline(question=question, context=qa_context)
            answer = qa_result['answer'].strip()
            confidence = qa_result['score']

            if confidence >= QA_CONFIDENCE_THRESHOLD and len(answer) > 3:
                answers.append({
                    'answer': answer,
                    'confidence': confidence,
                    'doc_index': i,
                    'meta': meta,
                    'context': qa_context[:200] + "..." if len(qa_context) > 200 else qa_context
                })
        except Exception as e:
            logger.warning(f"QA failed for doc {i}: {e}")
            continue

    if not answers:
        # Fallback: try to extract text from first meta
        best_context = _extract_text_from_meta(metas[0] if metas else {})
        return {
            'answer': best_context[:800] + "..." if len(best_context) > 800 else best_context,
            'confidence': 0.0,
            'doc_index': 0,
            'meta': metas[0] if metas else {},
            'context': best_context
        }

    # Sort by confidence and select best answer
    answers.sort(key=lambda x: x['confidence'], reverse=True)
    best_answer = answers[0]

    # Cross-validate with other high-confidence answers
    if len(answers) > 1:
        # Check if multiple documents agree on similar answers
        top_answers = answers[:3]  # Check top 3
        similar_answers = []
        for ans in top_answers:
            # Simple similarity check (could be improved with embeddings)
            if _answers_similar(best_answer['answer'], ans['answer']):
                similar_answers.append(ans)

        if len(similar_answers) >= 2:
            # Multiple documents agree, higher confidence
            best_answer['confidence'] = min(1.0, best_answer['confidence'] * 1.2)

    return best_answer


def _answers_similar(ans1: str, ans2: str) -> bool:
    """Check if two answers are similar (simple implementation)"""
    # Normalize and compare
    a1 = re.sub(r'[^\w\s\u0900-\u097F]', '', ans1.lower())
    a2 = re.sub(r'[^\w\s\u0900-\u097F]', '', ans2.lower())

    # Remove common stopwords
    stopwords = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'shall', 'be', 'with', 'to', 'for', 'of', 'and', 'or'}
    a1_words = set(a1.split()) - stopwords
    a2_words = set(a2.split()) - stopwords

    if not a1_words or not a2_words:
        return False

    # Check overlap
    overlap = len(a1_words & a2_words)
    total = len(a1_words | a2_words)

    return overlap / total >= 0.5 if total > 0 else False


def _translate_query_if_needed(query: str, lang: str) -> str:
    """Translate Hindi/Nepali queries to English for better processing"""
    if lang in ['hi', 'ne'] and _translator is not None:
        try:
            logger.info(f"Translating query from {lang} to English: '{query}'")
            translated = _translator.translate(query, src=lang, dest='en').text
            logger.info(f"Translated query: '{translated}'")
            return translated
        except Exception as e:
            logger.warning(f"Translation failed: {e}, using original query")
            return query
    return query


def _translate_answer_if_needed(answer: str, lang: str) -> str:
    """Translate answer back to user's language if needed"""
    if lang in ['hi', 'ne'] and _translator is not None:
        try:
            logger.info(f"Translating answer back to {lang}: '{answer[:50]}...'")
            translated = _translator.translate(answer, src='en', dest=lang).text
            logger.info(f"Translated answer: '{translated[:50]}...'")
            return translated
        except Exception as e:
            logger.warning(f"Answer translation failed: {e}, using English answer")
            return answer
    return answer





def _determine_best_dataset(query: str, lang: str) -> str:
    """Determine the most relevant dataset using semantic similarity with dataset representatives"""
    try:
        # Check embedding cache first
        cached_embedding = _get_cached_embedding(query, lang)
        if cached_embedding is not None:
            query_embedding = cached_embedding
        else:
            # Encode the query
            query_embedding = _sentence_model.encode([query])[0]
            _cache_embedding(query, lang, query_embedding)

        # Enhanced dataset representative descriptions for better semantic matching
        dataset_descriptions = {
            "BNS": "criminal offenses punishments penalties murder theft assault rape kidnapping robbery human trafficking crimes legal sections Bharatiya Nyaya Sanhita",
            "BSA": "evidence witness testimony documents proof admission confession expert court trial Bharatiya Sakshya Adhiniyam",
            "BNSS": "criminal procedure investigation police arrest bail summons warrant search seizure fir complaint registration appeal Bharatiya Nagarik Suraksha Sanhita"
        }

        # Compute similarities with each dataset representative
        similarities = {}
        for dataset, description in dataset_descriptions.items():
            desc_embedding = _sentence_model.encode([description])[0]
            similarity = cosine_similarity([query_embedding], [desc_embedding])[0][0]
            similarities[dataset] = similarity

        # Return the dataset with highest semantic similarity
        best_dataset = max(similarities, key=similarities.get)
        logger.info(f"Query: '{query}' -> Best dataset: {best_dataset} (similarities: {similarities})")
        return best_dataset

    except Exception as e:
        logger.warning(f"Semantic dataset selection failed: {e}, falling back to keyword-based selection")
        # Fallback to keyword-based selection
        query_lower = query.lower()

        # Enhanced keywords for each dataset with multilingual support
        bns_keywords = [
            'murder', 'theft', 'assault', 'rape', 'kidnapping', 'robbery', 'criminal', 'punishment', 'penalty', 'offense', 'crime', 'section', 'ipc',
            'हत्या', 'चोरी', 'हमला', 'बलात्कार', 'अपहरण', 'डकैती', 'सजा', 'दंड', 'अपराध', 'धारा',
            'हत्याको लागि', 'चोरी गर्नु', 'हमला गर्नु', 'बलात्कारको', 'अपहरणका लागि', 'डकैतीको', 'सजाय', 'दण्ड', 'अपराध', 'दफा', 'मानव तस्करी'
        ]
        bsa_keywords = [
            'evidence', 'witness', 'testimony', 'document', 'proof', 'admission', 'confession', 'expert', 'court', 'trial',
            'साक्षी', 'गवाही', 'दस्तावेज', 'सबूत', 'स्वीकारोक्ति', 'न्यायालय', 'मुकदमा',
            'साक्षीहरू', 'गवाहीहरू', 'कागजातहरू', 'प्रमाण', 'स्वीकारोक्ति', 'न्यायालय', 'मुद्दा'
        ]
        bnss_keywords = [
            'procedure', 'investigation', 'police', 'arrest', 'bail', 'summons', 'warrant', 'search', 'seizure', 'crpc', 'fir', 'complaint', 'registration', 'appeal',
            'प्रक्रिया', 'जांच', 'पुलिस', 'गिरफ्तारी', 'जमानत', 'समन', 'वारंट', 'तलाशी', 'कब्जा', 'एफआईआर', 'शिकायत', 'दर्ता', 'अपील',
            'प्रक्रिया', 'अनुसन्धान', 'प्रहरी', 'पक्राउ', 'जमानत', 'समन', 'वारेन्ट', 'खोज', 'जफत', 'एफआईआर', 'उजुरी', 'दर्ता', 'अपिल'
        ]

        # Count keyword matches
        bns_score = sum(1 for keyword in bns_keywords if keyword in query_lower)
        bsa_score = sum(1 for keyword in bsa_keywords if keyword in query_lower)
        bnss_score = sum(1 for keyword in bnss_keywords if keyword in query_lower)

        # Return dataset with highest score, default to BNS
        scores = {'BNS': bns_score, 'BSA': bsa_score, 'BNSS': bnss_score}
        best_dataset = max(scores, key=scores.get)
        logger.info(f"Keyword-based selection: '{query}' -> Best dataset: {best_dataset} (scores: {scores})")
        return best_dataset


# -----------------------
# Endpoints
# -----------------------
@app.get("/health")
def health() -> Dict[str, Any]:
    return {"status": "ok", "loaded_langs": list(_indexes.keys()), "model": "multilingual"}


@app.get("/langs")
def languages() -> Dict[str, Any]:
    return {"supported": sorted(list(SUPPORTED_LANGS))}


@app.post("/change-language")
async def change_language(request: LanguageChangeRequest):
    """
    Endpoint to notify backend about language change from frontend.
    This allows the backend to prepare or cache language-specific resources.
    """
    lang = request.language.lower()
    if lang not in SUPPORTED_LANGS:
        raise HTTPException(status_code=400, detail=f"Unsupported language: {lang}")

    # Here we can add logic to preload indexes for the new language if needed
    return {"status": "success", "language": lang, "message": f"Language changed to {lang}"}


@app.post("/chat", response_model=SearchResponse)
async def chat(request: ChatRequest):
    """
    Enhanced multilingual endpoint with improved accuracy and performance optimizations.

    Key improvements:
    1. Multilingual models (paraphrase-multilingual-mpnet-base-v2 + XLM-RoBERTa)
    2. Higher similarity threshold (0.3) for better precision
    3. Multi-document answer extraction and validation
    4. Cross-document answer agreement checking
    5. Better Hindi/Nepali text handling
    6. Query caching and simple query detection for performance
    """
    start_time = time.time()
    logger.info(f"Processing query: '{request.query}' in language: {request.language}")

    lang = (request.language or "en").lower()
    if lang not in SUPPORTED_LANGS:
        raise HTTPException(status_code=400, detail=f"Unsupported language: {lang}")

    # Translate query if needed for better processing
    processed_query = _translate_query_if_needed(request.query, lang)

    # Check for simple queries that don't need heavy processing
    if _is_simple_query(processed_query):
        logger.info(f"Detected simple query: '{processed_query}' - returning quick response")
        greeting_responses = {
            "en": "Hello! I'm your legal assistant. How can I help you with legal questions today?",
            "hi": "नमस्ते! मैं आपका कानूनी सहायक हूं। आज मैं आपकी कानूनी सवालों में कैसे मदद कर सकता हूं?",
            "ne": "नमस्ते! म तपाईको कानुनी सहायक हुँ। आज म तपाईका कानुनी प्रश्नहरूमा कसरी मद्दत गर्न सक्छु?"
        }
        return SearchResponse(
            language=lang,
            title="Greeting",
            explanation=greeting_responses.get(lang, greeting_responses["en"]),
            penalties=[],
            references=[],
            disclaimer="This is for educational purposes, not legal advice.",
            source_code="",
            source_name="",
        )

    # Check cache first
    cache_key = _get_cache_key(processed_query, lang)
    cached_response = _get_cached_response(cache_key)
    if cached_response:
        logger.info(f"Returning cached response for: {cache_key}")
        return SearchResponse(**cached_response)

    # Async preload models on first request for better performance
    await _preload_models_async()

    # Load only the most relevant dataset for the language to optimize performance
    # Determine best dataset based on processed query
    best_dataset = _determine_best_dataset(processed_query, lang)

    combined_texts = []
    combined_metas = []
    combined_embeddings = []
    dataset_sources = []  # Track which dataset each text comes from

    # Load only the best dataset instead of all datasets
    try:
        _load_index(lang, best_dataset)
        key = f"{lang}_{best_dataset}"
        store = _indexes.get(key)
        if store:
            combined_texts.extend(store["texts"])
            combined_metas.extend(store["metas"])
            combined_embeddings.append(store["embeddings"])
            # Add dataset source for each text
            dataset_sources.extend([best_dataset] * len(store["texts"]))
    except Exception as e:
        logger.warning(f"Failed to load index for {lang}/{best_dataset}: {e}")
        # Fallback: try to load any available dataset
        for dataset in DATASETS:
            try:
                _load_index(lang, dataset)
                key = f"{lang}_{dataset}"
                store = _indexes.get(key)
                if store:
                    combined_texts.extend(store["texts"])
                    combined_metas.extend(store["metas"])
                    combined_embeddings.append(store["embeddings"])
                    dataset_sources.extend([dataset] * len(store["texts"]))
                    break
            except Exception as e2:
                continue

    if not combined_embeddings:
        raise HTTPException(status_code=500, detail=f"No embeddings found for language {lang}")

    # Stack embeddings vertically
    combined_embeddings = np.vstack(combined_embeddings)

    if not request.query.strip():
        return SearchResponse(
            language=lang,
            title="",
            explanation="",
            penalties=[],
            references=[],
            disclaimer="This is for educational purposes, not legal advice.",
            source_code="",
            source_name="",
        )

    # Batch embedding optimization: Encode processed query with multilingual model
    cached_emb = _get_cached_embedding(processed_query, lang)
    if cached_emb is not None:
        query_embedding = cached_emb
        logger.info("Using cached query embedding")
    else:
        query_embedding = _sentence_model.encode([processed_query])[0]
        _cache_embedding(processed_query, lang, query_embedding)
        logger.info("Generated new query embedding")

    # Optimized similarity computation with batch processing
    similarities = cosine_similarity([query_embedding], combined_embeddings)[0]

    # Get top-k results for better accuracy
    ranked = sorted(range(len(similarities)), key=lambda i: -similarities[i])[:TOP_K_RETRIEVAL]

    # Filter by similarity threshold
    relevant_indices = [i for i in ranked if similarities[i] >= SIMILARITY_THRESHOLD]

    if not relevant_indices:
        no_results_msg = {
            "en": "No relevant results found. Try rephrasing your question.",
            "hi": "कोई प्रासंगिक परिणाम नहीं मिला। अपना प्रश्न फिर से लिखने का प्रयास करें।",
            "ne": "कुनै प्रासंगिक परिणाम फेला परेन। आफ्नो प्रश्न पुन: लेख्ने प्रयास गर्नुहोस्।"
        }
        return SearchResponse(
            language=lang,
            title="",
            explanation=no_results_msg.get(lang, no_results_msg["en"]),
            penalties=[],
            references=[],
            disclaimer="This is for educational purposes, not legal advice.",
            source_code="",
            source_name="",
        )

    # Extract top documents for answer generation (reduced to 3 for optimization)
    top_docs = [combined_texts[i] for i in relevant_indices[:3]]
    top_metas = [combined_metas[i] for i in relevant_indices[:3]]
    top_sources = [dataset_sources[i] for i in relevant_indices[:3]]

    # Use top documents directly without reranking
    top_indices = relevant_indices[:2]  # Use top 2 documents
    top_docs_final = [combined_texts[i] for i in top_indices]
    top_metas_final = [combined_metas[i] for i in top_indices]

    # Get best answer from multiple documents - async optimized version
    answer_result = await _extract_answer_from_multiple_docs_async(processed_query, top_docs_final, top_metas_final, lang)

    # Use the best document's metadata for response
    best_idx = relevant_indices[answer_result['doc_index']]
    meta0 = combined_metas[best_idx]
    source_dataset = dataset_sources[best_idx]

    # Get source information from metadata as backup
    meta_source = meta0.get("source", "")
    if meta_source and meta_source in DATASETS:
        source_dataset = meta_source

    # Keep source name separate for display
    source_name = DATASET_NAMES.get(source_dataset, source_dataset)

    # Extract section info from the sections array
    section_no = ""
    if 'sections' in meta0 and meta0['sections']:
        # Get the first section that has a section_no
        for sec in meta0['sections']:
            if sec.get('section_no'):
                section_no = str(sec['section_no'])
                break

    # Translate answer back to user's language if needed
    raw_answer = answer_result['answer']
    translated_answer = _translate_answer_if_needed(raw_answer, lang)

    # Format explanation with better structure like a professional chatbot
    if answer_result['confidence'] >= QA_CONFIDENCE_THRESHOLD:
        # Extract the full section text for better context
        full_section_text = _extract_text_from_meta(meta0)
        # Capitalize the first letter of the answer
        answer = translated_answer
        if answer and len(answer) > 0:
            answer = answer[0].upper() + answer[1:]

        # Create a more conversational and informative response
        # Include key legal information and context
        section_info = ""
        if section_no:
            section_info = f" (Section {section_no})"

        explanation = f"Based on {source_name}{section_info}, {answer.lower()}\n\nFor complete context, here's the relevant legal provision:\n\n{full_section_text[:1200] if len(full_section_text) > 1200 else full_section_text}"
    else:
        # Fallback response for low confidence - provide more context
        answer = translated_answer
        if answer and len(answer) > 0:
            answer = answer[0].upper() + answer[1:]

        # Enhanced fallback with more context
        full_section_text = _extract_text_from_meta(meta0)
        if section_no:
            explanation = f"According to Section {section_no} of {source_name}: {answer}\n\nRelevant legal text:\n\n{full_section_text[:800] if len(full_section_text) > 800 else full_section_text}"
        else:
            explanation = f"Based on the legal provisions: {answer}\n\nRelevant legal text:\n\n{full_section_text[:800] if len(full_section_text) > 800 else full_section_text}"

    chapter_title = meta0.get("chapter_title", "")
    # Removed reference text from explanation as it's now displayed separately in frontend

    # Format title with chapter name, section name and source information
    section_title = meta0.get("title", "")
    chapter_title = meta0.get("chapter_title", "")

    # Build title with chapter and section info
    if chapter_title and chapter_title.strip():
        if section_no:
            title = f"{chapter_title.strip()} - Section {section_no} ({source_dataset})"
        else:
            title = f"{chapter_title.strip()} ({source_dataset})"
    elif section_title and section_title.strip():
        title = section_title.strip()
    elif section_no:
        if lang == "hi":
            title = f"धारा {section_no}"
        elif lang == "ne":
            title = f"दफा {section_no}"
        else:
            title = f"Section {section_no}"
    else:
        title = "Legal Information"

    # Build references
    refs = []
    for i in relevant_indices[:5]:  # Show top 5 references
        m = combined_metas[i]
        source = dataset_sources[i]

        # Get source from metadata as backup
        meta_source_i = m.get("source", "")
        if meta_source_i and meta_source_i in DATASETS:
            source = meta_source_i

        # Extract section number for this specific reference
        ref_section_no = ""
        if 'sections' in m and m['sections']:
            for sec in m['sections']:
                if sec.get('section_no'):
                    ref_section_no = str(sec['section_no'])
                    break

        # Extract chapter number from ID or construct it
        chapter_no = ""
        ref_id = m.get("id", "")

        if ref_id:
            id_parts = ref_id.split("_ch")
            if len(id_parts) > 1:
                chapter_no = id_parts[1].split("_sec")[0]
        else:
            # If no ID, try to construct one from available data
            # Look for chapter info in the meta
            if m.get("chapter_title"):
                # Try to extract chapter number from title or other fields
                pass  # For now, leave empty and let frontend handle

        # If still no chapter, try to extract from the text or other meta fields
        if not chapter_no and m.get("chapter_no"):
            chapter_no = str(m["chapter_no"])

        # Construct ID if missing
        if not ref_id and ref_section_no:
            ref_id = f"{source}_ch{chapter_no}_sec{ref_section_no}"

        refs.append({
            "id": ref_id,
            "title": m.get("title", ""),
            "section": ref_section_no,  # Use section_no specific to this reference
            "source": source,
            "source_name": DATASET_NAMES.get(source, source),
            "type": m.get("type", ""),
            "score": round(float(similarities[i]), 4),
            "chapter": chapter_no,
        })

    # Multilingual disclaimer
    disclaimers = {
        "en": "This is for educational purposes, not legal advice. Please consult a qualified legal professional for actual legal matters.",
        "hi": "यह शैक्षिक उद्देश्यों के लिए है, कानूनी सलाह नहीं। वास्तविक कानूनी मामलों के लिए कृपया किसी योग्य कानूनी पेशेवर से परामर्श करें।",
        "ne": "यो शैक्षिक उद्देश्यका लागि हो, कानुनी सल्लाह होइन। वास्तविक कानुनी मामिलाहरूका लागि कृपया योग्य कानुनी व्यावसायीको परामर्श लिनुहोस्।"
    }

    # Create response object
    response = SearchResponse(
        language=lang,
        title=title,
        explanation=explanation,
        penalties=meta0.get("penalties", []) or [],
        references=refs,
        disclaimer=disclaimers.get(lang, disclaimers["en"]),
        source_code=source_dataset,
        source_name=source_name,
    )

    # Cache the response for future identical queries
    _cache_response(cache_key, response.dict())

    # Log processing time with detailed metrics
    processing_time = time.time() - start_time
    logger.info(f"Query processed in {processing_time:.2f}s: '{request.query}' - Confidence: {answer_result.get('confidence', 0):.3f}, Dataset: {source_dataset}, Lang: {lang}")

    return response


# Startup event for preloading
@app.on_event("startup")
async def startup_event():
    """Preload models and common indexes on startup for optimal performance"""
    logger.info("Starting Legal Advisor Backend with advanced optimizations...")
    start_time = time.time()
    try:
        # Preload models asynchronously with GPU support
        await _preload_models_async()
        model_load_time = time.time() - start_time
        logger.info(f"Models loaded in {model_load_time:.2f}s")

        # Preload common indexes
        index_start = time.time()
        _preload_common_indexes()
        index_load_time = time.time() - index_start
        logger.info(f"Indexes loaded in {index_load_time:.2f}s")

        total_time = time.time() - start_time
        logger.info(f"Startup preloading completed successfully in {total_time:.2f}s")
    except Exception as e:
        logger.warning(f"Startup preloading failed: {e}")


# Optional local runner
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
