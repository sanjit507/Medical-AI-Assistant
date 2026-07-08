# 🏥 Medical AI Assistant — Project Documentation

> A Retrieval-Augmented Generation (RAG) powered medical chatbot built with LangChain, Pinecone, Google Gemini, and Flask.

---

## 📌 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Project Structure](#4-project-structure)
5. [Module Reference](#5-module-reference)
6. [API Endpoints](#6-api-endpoints)
7. [Environment Variables](#7-environment-variables)
8. [Setup & Installation](#8-setup--installation)
9. [Indexing the Knowledge Base](#9-indexing-the-knowledge-base)
10. [Running the Application](#10-running-the-application)
11. [How It Works (Flow)](#11-how-it-works-flow)
12. [Dependencies](#12-dependencies)

---

## 1. Project Overview

**Medical AI Assistant** is an intelligent conversational chatbot designed to answer medical queries by searching through a curated medical knowledge base (PDF book). It uses:

- **Retrieval-Augmented Generation (RAG)** to ground answers in real medical content.
- **Pinecone** as a vector database to store and retrieve semantically similar text chunks.
- **Google Gemini 2.5 Flash** as the Large Language Model (LLM) for generating answers.
- **HuggingFace Sentence Transformers** for converting text into vector embeddings.
- **Flask** as the web framework to serve the chat interface.

The chatbot is capable of:
- Greeting users politely when they say hello.
- Answering medical questions based on the indexed PDF content.
- Responding with "I don't know" when the context doesn't contain relevant information (no hallucination).

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        USER BROWSER                         │
│                    (chat.html interface)                     │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP POST /get
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      FLASK APP (app.py)                      │
│                                                             │
│  1. Receives user message                                   │
│  2. Passes to RetrievalQA chain                             │
│  3. Returns LLM-generated response                          │
└────────────┬────────────────────────────────┬───────────────┘
             │                                │
             ▼                                ▼
┌────────────────────────┐      ┌─────────────────────────────┐
│   PINECONE VECTOR DB   │      │  GOOGLE GEMINI 2.5 FLASH    │
│   (Index: medical-bot) │      │        (LLM)                │
│                        │      │                             │
│  Stores embedded text  │      │  Generates final answer     │
│  chunks from PDF book  │◄────►│  from retrieved context     │
└────────────────────────┘      └─────────────────────────────┘
             ▲
             │  (One-time setup via store_index.py)
             │
┌────────────────────────────────────────────────────────────┐
│                 INDEXING PIPELINE (store_index.py)          │
│                                                             │
│  PDF → PyPDFLoader → Text Chunks → HuggingFace Embeddings  │
│                                   → Pinecone Index          │
└────────────────────────────────────────────────────────────┘
```

---

## 3. Tech Stack

| Layer              | Technology                                         |
|--------------------|----------------------------------------------------|
| Web Framework      | Flask                                              |
| LLM                | Google Gemini 2.5 Flash (`langchain-google-genai`) |
| Embeddings         | `sentence-transformers/all-MiniLM-L6-v2` (HuggingFace) |
| Vector Database    | Pinecone                                           |
| RAG Orchestration  | LangChain (`RetrievalQA`)                          |
| PDF Parsing        | LangChain `PyPDFLoader` + `DirectoryLoader`        |
| Text Splitting     | `RecursiveCharacterTextSplitter`                   |
| Frontend           | HTML + CSS + JavaScript (Jinja2 templates)         |
| Config Management  | `python-dotenv`                                    |
| Packaging          | `setuptools`                                       |

---

## 4. Project Structure

```
medical-ai-assistant/
│
├── app.py                  # Main Flask application & RAG chain setup
├── store_index.py          # One-time script: PDF → Pinecone index
├── template.py             # Script to scaffold project folder structure
├── setup.py                # Python package setup
├── requirements.txt        # Python dependencies
├── .env                    # Environment variables (API keys) — NOT committed
├── .gitignore              # Git ignore rules
├── DOCUMENTATION.md        # This file
│
├── src/                    # Core source package
│   ├── __init__.py
│   ├── helper.py           # PDF loading, text splitting, embeddings
│   └── prompt.py           # System prompt template for the LLM
│
├── data/                   # Knowledge base directory
│   └── Medical_book.pdf    # Source medical reference book (~15 MB)
│
├── templates/              # Jinja2 HTML templates
│   └── chat.html           # Main chat UI page
│
├── static/                 # Static assets (CSS, JS, images)
│
└── research/               # Experimental notebooks / research files
```

---

## 5. Module Reference

### `src/helper.py`

Contains three core utility functions used across the pipeline.

#### `load_pdf(data: str) -> list[Document]`

Loads all PDF files from the specified directory using LangChain's `DirectoryLoader` + `PyPDFLoader`.

| Parameter | Type | Description                                |
|-----------|------|--------------------------------------------|
| `data`    | str  | Path to the directory containing PDF files |

**Returns:** A list of LangChain `Document` objects (one per PDF page).

---

#### `text_split(extracted_data: list[Document]) -> list[Document]`

Splits raw documents into smaller overlapping text chunks suitable for embedding.

| Parameter        | Type           | Description                        |
|------------------|----------------|------------------------------------|
| `extracted_data` | list[Document] | Documents returned by `load_pdf()` |

**Chunking Parameters:**
- `chunk_size = 500` — Maximum characters per chunk
- `chunk_overlap = 20` — Overlap between consecutive chunks

**Returns:** A list of smaller `Document` chunks.

---

#### `download_hugging_face_embeddings() -> HuggingFaceEmbeddings`

Downloads and initializes the HuggingFace sentence-transformer model for embedding generation.

**Model used:** `sentence-transformers/all-MiniLM-L6-v2`

**Returns:** A `HuggingFaceEmbeddings` instance ready to encode text.

---

### `src/prompt.py`

Defines the **system prompt template** used to instruct the LLM.

```
prompt_template = """
You are a helpful and knowledgeable Medical AI Assistant.
If the user is just saying hello or asking about you, greet them politely
and introduce yourself as a Medical AI Assistant.
Otherwise, use the following pieces of information to answer the user's question.
If you don't know the answer to a medical question and the context is empty,
just say that you don't know, don't try to make up an answer.

Context: {context}
Question: {question}

Only return the helpful answer below and nothing else.
Helpful answer:
"""
```

**Template Variables:**

| Variable    | Description                                        |
|-------------|----------------------------------------------------|
| `{context}` | Retrieved text chunks from Pinecone vector search  |
| `{question}`| The user's question from the chat input            |

**Behaviors enforced by the prompt:**
- Politely greets users who say hello.
- Answers strictly from the provided context.
- Returns "I don't know" when context is empty — prevents hallucination.

---

### `app.py`

Main Flask application. Initializes the entire RAG pipeline at startup.

**Startup Sequence:**
1. Loads environment variables from `.env`.
2. Downloads HuggingFace embeddings model.
3. Connects to Pinecone and loads the existing `medical-bot` index.
4. Initializes Google Gemini LLM (`gemini-2.5-flash`, temperature=0.8).
5. Assembles a `RetrievalQA` chain with the custom prompt.

**LLM Configuration:**

| Parameter     | Value              |
|---------------|--------------------|
| Model         | `gemini-2.5-flash` |
| Temperature   | `0.8`              |
| Chain Type    | `stuff`            |
| Top-K Results | `2`                |

---

### `store_index.py`

A **one-time setup script** that builds the Pinecone vector index from the medical PDF.

**Workflow:**
```
data/ (PDF files)
    → load_pdf()          # Extract raw text pages
    → text_split()        # Chunk text into 500-char pieces
    → HuggingFace model   # Generate vector embeddings
    → PineconeVectorStore # Upload to Pinecone index
```

> ⚠️ Run this script only once (or when the knowledge base PDF changes).
> It uploads embeddings to Pinecone and may incur API usage costs.

---

## 6. API Endpoints

### `GET /`

Serves the main chat interface.

**Response:** Renders `templates/chat.html`

---

### `GET | POST /get`

Handles incoming chat messages and returns AI-generated responses.

**Request Form Field:**

| Field | Type   | Description              |
|-------|--------|--------------------------|
| `msg` | string | The user's chat message  |

**Response:** Plain text string containing the LLM's answer.

**Example Request:**
```
POST /get
Content-Type: application/x-www-form-urlencoded

msg=What+are+the+symptoms+of+diabetes?
```

**Example Response:**
```
Diabetes symptoms include frequent urination, excessive thirst,
unexplained weight loss, fatigue, blurred vision, and slow-healing sores.
```

---

## 7. Environment Variables

Create a `.env` file in the project root:

```env
PINECONE_API_KEY=your_pinecone_api_key_here
PINECONE_API_ENV=your_pinecone_environment_here
GOOGLE_API_KEY=your_google_ai_studio_key_here
```

| Variable           | Where to Get It                                           |
|--------------------|-----------------------------------------------------------|
| `PINECONE_API_KEY` | [Pinecone Console](https://app.pinecone.io)               |
| `PINECONE_API_ENV` | Pinecone project settings (e.g., `us-east-1-aws`)         |
| `GOOGLE_API_KEY`   | [Google AI Studio](https://aistudio.google.com/apikey)    |

> 🔒 **Security:** Never commit your `.env` file. It is already listed in `.gitignore`.

---

## 8. Setup & Installation

### Prerequisites

- Python 3.9+
- A [Pinecone](https://app.pinecone.io) account with an index named `medical-bot`
- A [Google AI Studio](https://aistudio.google.com) API key
- Git

### Steps

**1. Clone the repository:**
```bash
git clone https://github.com/sanjit507/Medical-AI-Assistant.git
cd Medical-AI-Assistant
```

**2. Create and activate a virtual environment:**
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS / Linux
python3 -m venv venv
source venv/bin/activate
```

**3. Install dependencies:**
```bash
pip install -r requirements.txt
```

**4. Configure environment variables:**
```bash
# Create .env file manually or copy from template
# Then fill in your API keys
```

---

## 9. Indexing the Knowledge Base

Run this **once** before starting the app for the first time, or whenever you update the PDF in `data/`:

```bash
python store_index.py
```

This script:
1. Reads all PDFs from `data/`
2. Splits them into 500-character chunks (20-char overlap)
3. Generates embeddings using HuggingFace `all-MiniLM-L6-v2`
4. Uploads vectors to your Pinecone index

> ⏳ May take a few minutes depending on PDF size and hardware.

---

## 10. Running the Application

```bash
python app.py
```

The app starts on:
```
http://0.0.0.0:8080
```

Open your browser and go to **http://localhost:8080**

> ⚠️ The app runs with `debug=True` by default. Set `debug=False` for production deployment.

---

## 11. How It Works (Flow)

```
User types a question
        │
        ▼
POST /get  ─── Flask receives msg
        │
        ▼
RetrievalQA.invoke({"query": msg})
        │
        ├──► Embed question with HuggingFace model
        │
        ├──► Pinecone: find top-2 semantically similar chunks
        │
        ├──► Build prompt: context (chunks) + question
        │
        └──► Google Gemini 2.5 Flash generates the answer
                │
                ▼
        Plain text response returned to browser
```

---

## 12. Dependencies

| Package                   | Purpose                                            |
|---------------------------|----------------------------------------------------|
| `flask`                   | Web framework — serves UI and API endpoints        |
| `langchain`               | Core RAG orchestration framework                   |
| `langchain-community`     | PDF loaders, HuggingFace embeddings integrations   |
| `langchain-pinecone`      | Pinecone vector store integration                  |
| `langchain-google-genai`  | Google Gemini LLM integration                      |
| `langchain-openai`        | OpenAI LLM integration (optional / future use)     |
| `langchain-experimental`  | Experimental LangChain features                    |
| `pinecone[grpc]`          | Pinecone client with gRPC for fast vector uploads  |
| `sentence-transformers`   | HuggingFace embedding model runtime                |
| `pypdf`                   | PDF parsing engine                                 |
| `python-dotenv`           | Loads environment variables from `.env` file       |

---

## 👤 Author

**Sanjit Kumar**
- 📧 Email: sanjitchaudhary506@gmail.com
- 🐙 GitHub: [sanjit507](https://github.com/sanjit507)

---

*Documentation for Medical AI Assistant v0.0.0*
