# PrivateGPT - Kubernetes Deployment

Production deployment of PrivateGPT RAG application on srt-hq-k8s cluster with vLLM integration.

## 🚀 Quick Start

### Development
```bash
# Local development (parent repo)
cd /mnt/c/Users/shaun/repos/privateGPT
poetry install --extras "ui llms-openai-like embeddings-huggingface vector-stores-qdrant"
PGPT_PROFILES=vllm poetry run python -m uvicorn private_gpt.main:app --reload --port 8001
```

### Docker
```powershell
# Build and test
cd manifests/apps/private-gpt
.\build-and-push.ps1

# Run locally
docker run -p 8001:8001 suparious/private-gpt:latest
```

### Kubernetes
```powershell
# Deploy (builds + pushes + deploys)
.\deploy.ps1 -Build -Push

# Deploy only (use existing image)
.\deploy.ps1

# Uninstall
.\deploy.ps1 -Uninstall
```

## 🛠️ Maintenance

### Update Deployment
```powershell
# Rebuild and redeploy
.\deploy.ps1 -Build -Push

# Force restart (no rebuild)
kubectl rollout restart deployment/private-gpt -n private-gpt
```

### View Logs
```bash
kubectl logs -n private-gpt -l app=private-gpt -f
```

### Troubleshooting
```bash
# Check all resources
kubectl get all,certificate,ingress,pvc -n private-gpt

# Describe pod
kubectl describe pod -n private-gpt -l app=private-gpt

# Check events
kubectl get events -n private-gpt --sort-by='.lastTimestamp'

# Test vLLM connectivity
kubectl exec -n private-gpt -it deployment/private-gpt -- \
  curl -s http://vllm.inference.svc.cluster.local:8000/v1/models
```

## 🏗️ Architecture

**Stack**:
- Python 3.11 + Poetry
- FastAPI (API framework)
- LlamaIndex 0.11.x (RAG)
- Gradio (Web UI)
- Qdrant (vector DB, embedded)
- Nomic Embed (embeddings)

**Platform Integration**:
- **LLM**: vLLM service at `http://vllm.inference.svc.cluster.local:8000/v1`
- **Storage**: 10Gi OpenEBS hostpath PVC
- **Ingress**: nginx-ingress with Let's Encrypt SSL
- **Model**: meta-llama/Meta-Llama-3.1-8B-Instruct

**Resources**:
- CPU: 500m request, 2000m limit
- Memory: 2Gi request, 4Gi limit
- Storage: 10Gi PVC (documents + Qdrant)

**Networking**:
- Service: ClusterIP on port 80 → container 8001
- Ingress: https://privategpt.lab.hq.solidrust.net
- API docs: https://privategpt.lab.hq.solidrust.net/docs

## ✨ Features

**RAG Capabilities**:
- Upload PDF, DOCX, TXT, MD documents
- Automatic document parsing and chunking
- Vector embedding with Nomic Embed
- Context-aware question answering
- OpenAI-compatible API

**Privacy & Security**:
- 100% local processing (no cloud APIs)
- SSL-encrypted ingress
- Non-root container
- Resource limits enforced
- Data persists on PVC

**Web UI (Gradio)**:
- Document upload and management
- Interactive chat interface
- File deletion controls
- Real-time responses

## 📁 Files Overview

```
manifests/apps/private-gpt/
├── Dockerfile                 # Multi-stage Python/Poetry build
├── build-and-push.ps1         # Docker automation
├── deploy.ps1                 # Kubernetes deployment
├── .dockerignore              # Build exclusions
├── CLAUDE.md                  # Comprehensive agent context
├── README-K8S.md              # This file
└── k8s/                       # Kubernetes manifests
    ├── 01-namespace.yaml      # Namespace: private-gpt
    ├── 02-configmap.yaml      # vLLM configuration
    ├── 03-pvc.yaml            # 10Gi persistent storage
    ├── 04-deployment.yaml     # Application deployment (1 replica)
    ├── 05-service.yaml        # ClusterIP service
    └── 06-ingress.yaml        # SSL ingress
```

## 🔍 Useful Commands

```bash
# Status
kubectl get all,certificate,ingress,pvc -n private-gpt

# Logs
kubectl logs -n private-gpt -l app=private-gpt -f

# Shell access
kubectl exec -n private-gpt -it deployment/private-gpt -- /bin/bash

# Storage usage
kubectl exec -n private-gpt -it deployment/private-gpt -- df -h /app/local_data

# Check vLLM dependency
kubectl get pods -n vllm-inference

# Port forward (for testing)
kubectl port-forward -n private-gpt svc/private-gpt 8001:80

# Update config
kubectl edit configmap private-gpt-config -n private-gpt
kubectl rollout restart deployment/private-gpt -n private-gpt
```

## 🌐 Links

- **Production**: https://privategpt.lab.hq.solidrust.net
- **API Docs**: https://privategpt.lab.hq.solidrust.net/docs
- **Docker Hub**: https://hub.docker.com/r/suparious/private-gpt
- **GitHub**: https://github.com/suparious/privateGPT
- **Upstream**: https://github.com/zylon-ai/private-gpt
- **Documentation**: https://docs.privategpt.dev/

---

**Last Updated**: 2025-11-13  
**Platform**: srt-hq-k8s Production Cluster  
**Namespace**: private-gpt  
**Maintainer**: Shaun Prince
