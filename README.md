# Medical AI Assistant 🩺🤖

A Retrieval-Augmented Generation (RAG) based Medical AI Chatbot designed to provide accurate, context-aware answers to medical queries by indexing and retrieving information from authoritative medical literature.

---

## 📋 Table of Contents
1. [Overview](#-overview)
2. [Key Use Cases](#-key-use-cases)
3. [Technology Stack](#-technology-stack)
4. [System Architecture & Working Diagram](#-system-architecture--working-diagram)
5. [Project Directory Structure](#-project-directory-structure)
6. [Prerequisites & Environment Configuration](#-prerequisites--environment-configuration)
7. [Installation & Setup Guide](#-installation--setup-guide)
8. [Usage Instructions](#-usage-instructions)
9. [Important Disclaimers](#-important-disclaimers)

---

## 🌟 Overview

The **Medical AI Assistant** is a web-based chatbot system that utilizes **Retrieval-Augmented Generation (RAG)** to provide reliable answers to health and medical-related questions. 

Unlike general-purpose conversational LLMs that may suffer from hallucinations, this assistant grounds its responses in a trusted source of medical knowledge (e.g., a comprehensive medical textbook or reference guide). By combining **semantic search** using a vector database with Google's state-of-the-art **Gemini model**, it ensures that answers are both medically informed and naturally phrased.

---

## 💡 Key Use Cases

*   **Interactive Medical Reference:** Allows medical students, practitioners, and researchers to quickly search, query, and synthesize information from large textbooks (such as the default *Medical_book.pdf*) through a conversational interface.
*   **Patient Health Literacy:** Helps patients understand medical terms, symptoms, disease mechanisms, and treatments in simple language, based on validated medical texts.
*   **First-Aid & General Symptom Inquiry:** Provides instant guidance on common medical conditions and general safety guidelines.
*   **Educational Q&A:** Serves as an interactive study buddy for clinical concepts, anatomy, pharmacology, and pathology.

---

## 🛠️ Technology Stack

The application is built using a modern AI-stack integrated with Python:

| Component | Technology / Library | Role |
|---|---|---|
| **Frontend** | HTML5, CSS3, Bootstrap 4, jQuery, FontAwesome | User interface layout, styling, and AJAX-based chat logic |
| **Backend** | Flask (Python) | Lightweight web server hosting UI endpoints and orchestrating RAG queries |
| **Orchestration** | LangChain | Framework for PDF loaders, text splitters, custom prompt templates, and RetrievalQA chains |
| **Embeddings** | HuggingFace (`sentence-transformers/all-MiniLM-L6-v2`) | Local execution to generate dense, 384-dimensional semantic text vectors |
| **Vector Database** | Pinecone | Cloud-hosted vector database for storing and querying text embeddings |
| **Large Language Model** | Google Gemini (`gemini-2.5-flash` via `langchain-google-genai`) | Reasoning engine to synthesize retrieved passages into natural answers |

---

## 🏗️ System Architecture & Working Diagram

The project splits workflows into two key pipelines: **Data Ingestion** (pre-computation) and **Query & Retrieval** (runtime).

### 1. Visual Workflow (Mermaid)

```mermaid
flowchart TD
    subgraph Data Ingestion Pipeline (store_index.py)
        A[Medical Book PDF] -->|DirectoryLoader| B[Raw Text Documents]
        B -->|RecursiveCharacterTextSplitter| C[Text Chunks (Size: 500, Overlap: 20)]
        C -->|HuggingFace Embeddings| D[Dense Semantic Vectors]
        D -->|Upload| E[(Pinecone Vector DB)]
    end

    subgraph Chatbot Query Pipeline (app.py)
        F[User Query via Web UI] -->|HuggingFace Embeddings| G[Query Vector]
        G -->|Semantic Similarity Search| E
        E -->|Retrieve Top K=2 Matches| H[Context Passages]
        H & F -->|Combine into Custom Prompt Template| I[Enriched Prompt]
        I -->|API Call| J[Google Gemini 2.5 Flash]
        J -->|Generate Grounded Response| K[Helpful Medical Answer]
        K -->|Display| L[Web Chat UI]
    end

    style E fill:#005cbf,stroke:#333,stroke-width:2px,color:#fff
    style J fill:#17a2b8,stroke:#333,stroke-width:2px,color:#fff
```

### 2. Conceptual Flow Diagram (ASCII)

```
[ INGESTION PIPELINE ]
  Medical PDF -> Text Splitting -> HF Embedding Model -> Vector Storage (Pinecone DB)

[ RUNTIME CHAT PIPELINE ]
                               +-----------------------------+
                               |     User Input Query        |
                               +--------------+--------------+
                                              |
                                              v
                              +-------------------------------+
                              | Search Pinecone Vector Index  |
                              +---------------+---------------+
                                              |
                                              v
                              +---------------+---------------+
                              |    Retrieve Top-K Context     |
                              +---------------+---------------+
                                              |
                                              v
  +------------------+        +---------------+---------------+
  |  System Prompt   |------> |    Construct Prompt Template  |
  +------------------+        +---------------+---------------+
                                              |
                                              v
                              +---------------+---------------+
                              | Google Gemini 2.5 Flash Model |
                              +---------------+---------------+
                                              |
                                              v
                               +--------------+--------------+
                               |    Grounded Answer to Web   |
                               +-----------------------------+
```

---

## 📂 Project Directory Structure

```directory
medical-ai-assistant/
├── data/
│   └── Medical_book.pdf          # Source medical knowledge base PDF
├── research/
│   └── trials.ipynb              # Jupyter notebook containing RAG experiment code
├── src/
│   ├── __init__.py               # Python package constructor
│   ├── helper.py                 # Core modules for loading, splitting, and embedding
│   └── prompt.py                 # Custom system templates for chatbot answers
├── static/
│   └── style.css                 # Custom CSS styling for the chatbot chat UI
├── templates/
│   └── chat.html                 # Flask HTML page displaying the conversational interface
├── .env                          # Configuration file for API keys (must be created)
├── .gitignore                    # Lists paths ignored by Git (venv, envs, etc.)
├── app.py                        # Web application server entrypoint (Flask)
├── requirements.txt              # Project package requirements and dependencies
├── setup.py                      # Setup configuration for custom package discovery
├── store_index.py                # Command-line script to ingest PDF and build Pinecone DB
└── template.py                   # Initial scaffolding utility tool
```

---

## 🔑 Prerequisites & Environment Configuration

Create a `.env` file in the root directory of the project with the following configuration variables:

```env
PINECONE_API_KEY="your-pinecone-api-key"
GOOGLE_API_KEY="your-gemini-google-api-key"
PINECONE_INDEX_NAME="your-pinecone-index-name"
```

> [!IMPORTANT]
> Make sure the index name defined under `PINECONE_INDEX_NAME` matches the index name you create/use inside `store_index.py` and `app.py`. By default, `store_index.py` references `aiddata` and `app.py` references `medical-bot`. To ensure successful execution, ensure these values align!

---

## 🚀 Installation & Setup Guide

Follow these steps to set up and run the project locally:

### Step 1: Clone the repository
```bash
git clone <repository_url>
cd medical-ai-assistant
```

### Step 2: Set up a virtual environment (Recommended)
```powershell
python -m venv venv
venv\Scripts\activate
```

### Step 3: Install dependencies
Install all required libraries specified in the `requirements.txt` file and locally link modules:
```bash
pip install -r requirements.txt
```

### Step 4: Add your Medical Book
Place the reference PDF document (e.g., `Medical_book.pdf`) in the `data/` folder in the root directory.

### Step 5: Ingest data into Pinecone
Run the indexing script to parse the PDF, generate embeddings, and upload them to your Pinecone Vector Database:
```bash
python store_index.py
```

### Step 6: Start the Flask application
Launch the web interface locally:
```bash
python app.py
```

Open your browser and navigate to `http://localhost:8080` (or `http://127.0.0.1:8080`) to interact with the Medical AI Assistant.

---

## 💬 Usage Instructions

1.  **Chat Interface:** Type your medical inquiry in the message input field at the bottom and click the Send icon.
2.  **RAG Processing:** The system will search for contextual references in `Medical_book.pdf` stored in Pinecone, pass the top findings to Google Gemini, and display the answer.
3.  **Accuracy Safeguards:** If you ask a medical question that is not covered by the text, the assistant is instructed not to hallucinate, responding that it does not know the answer.

---

## ⚠️ Important Disclaimers

> [!WARNING]
> **Educational & Informational Use Only:** This application is a prototype demonstrating a Retrieval-Augmented Generation (RAG) system. It is **not** a replacement for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare professional regarding any medical condition. Never disregard professional medical advice or delay in seeking it because of information generated by this chatbot.
