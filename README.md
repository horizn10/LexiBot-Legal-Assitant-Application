🚀 LexiBot — Smart Legal Assistant for India’s New Criminal Laws

A multilingual AI-driven legal assistant for BNS • BNSS • BSA


LexiBot is an AI-powered legal assistant designed to simplify India’s newly introduced criminal laws — Bharatiya Nyaya Sanhita (BNS 2023), Bharatiya Nagarik Suraksha Sanhita (BNSS 2023) and Bharatiya Sakshya Adhiniyam (BSA 2023).
It delivers fast, context-aware, multilingual legal responses using semantic search, transformer-based question answering, and an intuitive Flutter mobile interface.

📌 Features
🔍 AI-Powered Legal Answers

Retrieves exact legal provisions using semantic vector embeddings (384-dim).

Extractive QA with XLM-RoBERTa and DistilBERT.

Provides section number, title, punishment, description, and cross-references.

🌐 Multilingual Support

English, Hindi, and Nepali text queries

Hindi/Nepali → English translation pipeline

Full multilingual UI using Flutter localization

⚡ Real-Time Performance

2–3 seconds average response time

Efficient similarity search using cosine similarity

Optimized caching and batching

🔐 Privacy & Reliability

Processes data locally (no external API dependency)

100% control over legal dataset

82–88% query accuracy on multilingual test set

📱 Cross-Platform Mobile App

Built with Flutter

Clean UI with navigation, section explorer, and chatbot

Voice input (English) using speech-to-text

Dark mode friendly

📴 Optional Offline Mode

Convert the model to ONNX and run everything on-device for full offline functionality.

🧠 Architecture Overview
1. Dataset Processing

Sources: Official Govt. of India documents (BNS/BNSS/BSA).
Processing Steps:

PDF text extraction

Section-wise segmentation

Unicode normalization (NFC)

Metadata tagging

Saved as JSON + Pickle

📄 Refer: Chapter 2 – Methodology in the project report.

2. Semantic Embedding Layer

Model: paraphrase-MiniLM-L6-v2

Output: 384-dimensional vectors

Language alignment: English, Hindi, Nepali

Stored as .npy, .pkl, .metas

3. Query Understanding Pipeline

Language detection

Optional translation to English

Query embedding

Cosine similarity search (Top-K = 5)

Threshold filtering

4. Answer Extraction

Primary Model: XLM-RoBERTa (SQuAD2 fine-tuned)

Fallback: DistilBERT

Outputs clean, concise, justified responses.

5. Flutter Frontend

Bottom navigation (Home • Chatbot • Language • Settings)

Language toggle with instant UI updates

Voice query support

Modern card-based section viewer

🧪 Performance Metrics
Metric	Result	Notes
Response Time	2–3s	On Ryzen 5 7000 + 16GB RAM
Accuracy (Top-1)	82–88%	On 200 queries across 3 languages
CPU Usage	18–22%	During active querying
RAM Usage	550–700MB	Backend + embeddings
Supported Languages	3	English, Hindi, Nepali

📊 Extracted from Table 3.4.3 – Performance Metrics.


📱 Screenshots

(Add images when uploading your assets)

/assets/home_screen.png
/assets/chat_screen.png
/assets/language_toggle.png


Or keep placeholders like:

🏠 Home Interface

💬 Chatbot Screen

🌐 Language Switcher

🇳🇵 Nepali UI Example

🛠️ Tech Stack
Backend

FastAPI

Uvicorn

Transformers (HuggingFace)

Sentence-Transformers

scikit-learn

Googletrans (for Hindi/Nepali translation)

Frontend

Flutter (Dart)

Provider (State Management)

speech_to_text

flutter_tts

NotoSans fonts (Devanagari support)

📁 Project Structure (Suggested)
lexibot/
│── backend/
│   ├── main.py
│   ├── ingest_data.py
│   ├── models/
│   ├── embeddings/
│   ├── utils/
│
│── frontend/
│   ├── lib/
│   ├── assets/
│   ├── localization/
│   ├── screens/
│
│── datasets/
│   ├── BNS/
│   ├── BNSS/
│   ├── BSA/
│
│── README.md

🚧 Future Enhancements

✔ Fully offline ONNX-based inference

✔ Expand to case-law + precedent retrieval

✔ Add RAG (Retrieval Augmented Generation)

✔ Add more Indian languages

✔ Better UI animations and personalized legal guidance

✔ Smart PDF reader for automatic legal question extraction

🔮 As mentioned in the Future Scope section:


📜 Author

Kshitiz Boral


⭐ Support & Contributions

Feel free to open issues, request features, or contribute improvements.
Your feedback helps make LexiBot smarter and more accessible.
