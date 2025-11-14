# Multi-stage build for PrivateGPT
# Stage 1: Builder - Install dependencies
FROM python:3.11-slim AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_VERSION=1.8.3 \
    POETRY_HOME="/opt/poetry" \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_VIRTUALENVS_CREATE=true
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="$POETRY_HOME/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Install dependencies (without dev dependencies)
# Install with ui,llms-openai-like,embeddings-huggingface,vector-stores-qdrant extras
RUN poetry install --no-root --no-dev --extras "ui llms-openai-like embeddings-huggingface vector-stores-qdrant"

# Stage 2: Runtime
FROM python:3.11-slim

# Install runtime system dependencies
RUN apt-get update && apt-get install -y \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 -s /bin/bash privategpt

# Set working directory
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Copy application code
COPY --chown=privategpt:privategpt . .

# Create necessary directories
RUN mkdir -p /app/local_data /app/models /app/tiktoken_cache && \
    chown -R privategpt:privategpt /app

# Switch to non-root user
USER privategpt

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PGPT_PROFILES=vllm

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8001/health', timeout=5)" || exit 1

# Run application
CMD ["python", "-m", "uvicorn", "private_gpt.main:app", "--host", "0.0.0.0", "--port", "8001"]
