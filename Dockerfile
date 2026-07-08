# ──────────────────────────────────────────────
#  Stage 1: Builder — install Python dependencies
# ──────────────────────────────────────────────
FROM python:3.11-slim AS builder

# Prevent Python from writing .pyc files and enable unbuffered logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install build tools needed for some ML packages (e.g. sentence-transformers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency manifests AND the local package (needed for `-e .` in requirements.txt)
COPY requirements.txt .
COPY setup.py .
COPY src/ ./src/

RUN pip install --upgrade pip \
    && pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu \
    && pip install --no-cache-dir -r requirements.txt


# ──────────────────────────────────────────────
#  Stage 2: Runtime — lean production image
# ──────────────────────────────────────────────
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    # Tell Flask not to run in debug mode in production
    FLASK_ENV=production \
    FLASK_APP=app.py \
    # Set Hugging Face cache directory to a writable path for the non-root user
    HF_HOME=/tmp/hf_cache

WORKDIR /app

# Copy installed Python packages from builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application source code
COPY app.py         ./app.py
COPY setup.py       ./setup.py
COPY src/           ./src/
COPY templates/     ./templates/
COPY static/        ./static/

# The data/ directory (PDF) should be mounted at runtime via a volume,
# NOT baked into the image to keep it lightweight.
# If you want to bundle the PDF, uncomment the line below:
# COPY data/ ./data/

# Create a non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

# Expose the Flask port
EXPOSE 8080

# Health check — pings the root endpoint every 30s
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/')" || exit 1

# Start the Flask application
CMD ["python", "app.py"]
