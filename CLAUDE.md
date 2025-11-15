# CLAUDE.md - PrivateGPT Kubernetes Deployment

**Project**: PrivateGPT - Private RAG Application with vLLM Integration
**Status**: Production-Ready
**URL**: https://privategpt.lab.hq.solidrust.net
**Shaun's Golden Rule**: No workarounds, no temp fixes, complete solutions only

---

## ⚡ AGENT QUICK START

**You are working in the PrivateGPT submodule** (`manifests/apps/private-gpt/`), which is part of the srt-hq-k8s platform.

**What is PrivateGPT?**
- **Private RAG application** using LlamaIndex and FastAPI
- **100% local inference** via platform vLLM service
- **Document ingestion** with vector storage (Qdrant)
- **Gradio UI** for chat and document upload
- **OpenAI-compatible API** for programmatic access

**Key Integration Points**:
- **vLLM Service**: `http://vllm.inference.svc.cluster.local:8000/v1`
- **Storage**: 10Gi PVC for documents and vector database
- **Ingress**: SSL-enabled via cert-manager DNS-01

**When You Need Platform Info**: Query ChromaDB (see section below)

---

## 📚 PLATFORM INTEGRATION (ChromaDB Knowledge Base)

**When working in this submodule**, you cannot access the parent srt-hq-k8s repository files. Use ChromaDB to query platform capabilities and integration patterns.

**Collection**: `srt-hq-k8s-platform-guide` (43 docs, updated 2025-11-11)

**Why This Matters for PrivateGPT**:
PrivateGPT integrates deeply with the srt-hq-k8s platform:
- **vLLM Integration**: Uses platform vLLM service for all LLM inference
- **Storage**: Requires persistent storage for ingested documents and Qdrant vector DB
- **Ingress**: Exposed via nginx-ingress with Let's Encrypt SSL (DNS-01)
- **Monitoring**: Integrated with platform Prometheus/Grafana stack
- **Networking**: Service-to-service communication within cluster

**Query When You Need**:
- Platform architecture and service discovery patterns
- vLLM service endpoints and configuration
- Storage class options (OpenEBS hostpath, NVMe, SATA)
- Ingress patterns and SSL certificate setup
- Monitoring and observability integrations
- GPU resource allocation (if needed for embeddings)

**Example Queries**:
```
"What is the vLLM service endpoint in the cluster?"
"What storage classes are available in srt-hq-k8s?"
"How do I configure ingress with SSL certificates?"
"What monitoring tools are available on the platform?"
```

**When NOT to Query**:
- ❌ PrivateGPT application logic (see README.md in parent repo)
- ❌ LlamaIndex usage patterns (see LlamaIndex docs)
- ❌ Python/Poetry development (use project documentation)
- ❌ Docker build process (use build-and-push.ps1)

**How to Query**:
Use the MCP Chroma tools:
```
mcp__chroma__chroma_query_documents(
  collection_name: "srt-hq-k8s-platform-guide",
  query_texts: ["your question here"],
  n_results: 5
)
```

---

## 📍 Project Overview

**PrivateGPT** is a production-ready RAG (Retrieval Augmented Generation) application that allows asking questions about uploaded documents using LLMs, with 100% privacy - no data leaves the cluster.

**Key Features**:
- **Document Ingestion**: Upload PDF, DOCX, TXT, MD files
- **RAG Pipeline**: Context-aware question answering
- **OpenAI-Compatible API**: Use with any OpenAI SDK
- **Gradio UI**: Web interface for chat and file management
- **Local Vector Store**: Qdrant for document embeddings
- **vLLM Integration**: Fast inference via platform service

**Use Cases**:
- Private document Q&A for sensitive materials
- Knowledge base chat for internal documentation
- RAG development and experimentation
- Legal/healthcare document analysis (HIPAA/privacy-compliant)

---

## 🗂️ LOCATIONS

**Repository Locations**:
- **Parent Repo**: `/mnt/c/Users/shaun/repos/privateGPT` (upstream source)
- **Submodule**: `/mnt/c/Users/shaun/repos/srt-hq-k8s/manifests/apps/private-gpt/` (K8s deployment)
- **Platform Repo**: `/mnt/c/Users/shaun/repos/srt-hq-k8s` (not accessible from submodule)

**Deployment URLs**:
- **Production**: https://privategpt.lab.hq.solidrust.net
- **API**: https://privategpt.lab.hq.solidrust.net/docs (FastAPI Swagger)
- **Health**: https://privategpt.lab.hq.solidrust.net/health

**Container Images**:
- **Docker Hub**: suparious/private-gpt:latest
- **Registry**: Docker Hub (public)

---

## 🛠️ TECH STACK

**Backend**:
- Python 3.11 (Poetry for dependency management)
- FastAPI (API framework)
- LlamaIndex 0.11.x (RAG framework)
- Gradio (Web UI)
- Qdrant (vector database, embedded mode)
- Nomic Embed (embedding model)

**LLM Integration**:
- vLLM service (OpenAI-like API)
- Model: meta-llama/Meta-Llama-3.1-8B-Instruct
- Endpoint: http://vllm.inference.svc.cluster.local:8000/v1

**Infrastructure**:
- Kubernetes deployment (single replica with PVC)
- Persistent storage: 10Gi OpenEBS hostpath
- Ingress: nginx-ingress with Let's Encrypt SSL
- Health checks: HTTP GET /health

---

## 📁 PROJECT STRUCTURE

```
manifests/apps/private-gpt/
├── Dockerfile                    # Multi-stage Python/Poetry build
├── build-and-push.ps1            # Docker build/push automation
├── deploy.ps1                    # Kubernetes deployment script
├── .dockerignore                 # Docker build exclusions
├── CLAUDE.md                     # This file - agent context
├── README-K8S.md                 # Kubernetes deployment guide
└── k8s/                          # Kubernetes manifests
    ├── 01-namespace.yaml         # private-gpt namespace
    ├── 02-configmap.yaml         # vLLM settings configuration
    ├── 03-pvc.yaml               # 10Gi storage for data
    ├── 04-deployment.yaml        # Application deployment
    ├── 05-service.yaml           # ClusterIP service
    └── 06-ingress.yaml           # SSL ingress
```

**Parent Repository** (not in submodule, see ChromaDB for info):
```
/mnt/c/Users/shaun/repos/privateGPT/
├── private_gpt/                  # Main application code
├── settings-vllm.yaml            # vLLM configuration template
├── pyproject.toml                # Poetry dependencies
└── ... (see parent repo README)
```

---

## 🚀 DEVELOPMENT WORKFLOW

### Local Development (Parent Repo)
```bash
cd /mnt/c/Users/shaun/repos/privateGPT

# Install dependencies
poetry install --extras "ui llms-openai-like embeddings-huggingface vector-stores-qdrant"

# Run locally (requires local vLLM or OpenAI API)
PGPT_PROFILES=vllm poetry run python -m uvicorn private_gpt.main:app --reload --port 8001

# Access UI
open http://localhost:8001
```

### Docker Development
```bash
cd /mnt/c/Users/shaun/repos/srt-hq-k8s/manifests/apps/private-gpt

# Build image
.\build-and-push.ps1

# Test locally
docker run -p 8001:8001 -e PGPT_PROFILES=vllm suparious/private-gpt:latest
```

### Production Deployment
```bash
cd /mnt/c/Users/shaun/repos/srt-hq-k8s/manifests/apps/private-gpt

# Deploy with build
.\deploy.ps1 -Build -Push

# Deploy only (use existing image)
.\deploy.ps1
```

---

## 📋 DEPLOYMENT

### Quick Deploy
```powershell
cd manifests/apps/private-gpt
.\deploy.ps1 -Build -Push
```

**What happens**:
1. Builds Docker image with Poetry dependencies
2. Pushes to suparious/private-gpt:latest
3. Applies Kubernetes manifests
4. Waits for rollout completion
5. Displays status and URLs

### Manual Deployment
```bash
# Build and push image
.\build-and-push.ps1 -Login -Push

# Apply manifests
kubectl apply -f k8s/

# Wait for rollout
kubectl rollout status deployment/private-gpt -n private-gpt --timeout=5m

# Check status
kubectl get all,certificate,ingress,pvc -n private-gpt
```

### Prerequisites
- vLLM service must be running (`kubectl get pods -n vllm-inference`)
- Docker Hub authentication (`docker login`)
- Kubernetes cluster access (`kubectl cluster-info`)

---

## 🔧 COMMON TASKS

### View Logs
```bash
# Follow application logs
kubectl logs -n private-gpt -l app=private-gpt -f

# Check startup logs
kubectl logs -n private-gpt -l app=private-gpt --tail=100
```

### Update Deployment
```bash
# Rebuild and redeploy
cd manifests/apps/private-gpt
.\deploy.ps1 -Build -Push

# Force restart (without rebuilding)
kubectl rollout restart deployment/private-gpt -n private-gpt
```

### Configuration Changes
```bash
# Edit vLLM settings
kubectl edit configmap private-gpt-config -n private-gpt

# Restart to apply changes
kubectl rollout restart deployment/private-gpt -n private-gpt
```

### Storage Management
```bash
# Check PVC status
kubectl get pvc -n private-gpt

# View storage usage (exec into pod)
kubectl exec -n private-gpt -it deployment/private-gpt -- df -h /app/local_data

# Browse uploaded files
kubectl exec -n private-gpt -it deployment/private-gpt -- ls -lah /app/local_data
```

### Troubleshooting

**Pod not starting**:
```bash
# Check pod status
kubectl describe pod -n private-gpt -l app=private-gpt

# Check events
kubectl get events -n private-gpt --sort-by='.lastTimestamp'

# Check vLLM dependency
kubectl get pods -n vllm-inference
```

**Certificate not issuing**:
```bash
# Check certificate status
kubectl get certificate -n private-gpt

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f
```

**Application errors**:
```bash
# Check logs for errors
kubectl logs -n private-gpt -l app=private-gpt --tail=200 | grep -i error

# Check vLLM connectivity
kubectl exec -n private-gpt -it deployment/private-gpt -- \
  curl -s http://vllm.inference.svc.cluster.local:8000/v1/models
```

### Uninstall
```powershell
.\deploy.ps1 -Uninstall
```

**Warning**: This deletes the PVC and all uploaded documents!

---

## 🎯 USER PREFERENCES (CRITICAL)

**Shaun's Requirements** (MUST FOLLOW):

**Solutions**:
- ✅ Complete, immediately deployable, production-ready
- ✅ Run PowerShell/Makefile directly (don't ask permission)
- ✅ Full manifests (not patches), reproducible
- ❌ NO workarounds, temp files, disabled features, cruft

**Workflow**:
- User monitors changes in real-time, stops/corrects anything off-vision
- Validate end-to-end, document in appropriate location
- Security-first: no exposed secrets, proper RBAC, non-root containers

**Code Quality**:
- Production-grade error handling
- Comprehensive health checks
- Resource limits on all containers
- Proper logging and observability

---

## 💡 KEY DECISIONS

### Why Single Replica?
- **PVC with ReadWriteOnce**: Only one pod can mount the volume
- **Embedded Qdrant**: Runs in-process, not clustered
- **Stateful data**: Uploaded documents and vector DB state
- **Alternative**: Could use external Qdrant cluster for HA, but adds complexity

### Why OpenEBS Hostpath Storage?
- **Fast local storage**: Documents and vectors on node disk
- **Simple**: No network overhead
- **Sufficient for non-critical data**: Can be re-ingested if lost
- **Alternative**: TrueNAS NFS for durability, but slower

### Why vLLM Integration?
- **Platform consistency**: All apps use same inference backend
- **Cost efficiency**: No external API costs
- **Privacy**: 100% local, no data sent to cloud
- **Performance**: Fast inference with vLLM optimizations

### Why Poetry in Docker?
- **Dependency management**: Poetry handles complex Python deps
- **Reproducible builds**: Lock file ensures consistency
- **Virtual environments**: Isolated from system Python
- **Alternative**: pip with requirements.txt, but less robust

### Resource Allocation
- **CPU**: 500m request, 2000m limit (RAG operations can be CPU-intensive)
- **Memory**: 2Gi request, 4Gi limit (embedding models + documents in memory)
- **Storage**: 10Gi PVC (scalable for more documents)

---

## 🔍 VALIDATION

**Post-Deployment Verification**:

1. **Check Deployment Status**:
   ```bash
   kubectl get all,certificate,ingress,pvc -n private-gpt
   ```
   - Expect: 1/1 pod running, service with ClusterIP, ingress with ADDRESS

2. **Verify Certificate**:
   ```bash
   kubectl get certificate -n private-gpt
   ```
   - Expect: READY=True (may take 1-2 minutes)

3. **Test Health Endpoint**:
   ```bash
   curl -k https://privategpt.lab.hq.solidrust.net/health
   ```
   - Expect: HTTP 200 response

4. **Browser Test**:
   - Open: https://privategpt.lab.hq.solidrust.net
   - Expect: Green padlock, Gradio UI loads
   - Test: Upload a text file, ask a question about it

5. **API Test**:
   ```bash
   # Check OpenAPI docs
   curl -k https://privategpt.lab.hq.solidrust.net/docs

   # Test embeddings endpoint
   curl -k https://privategpt.lab.hq.solidrust.net/v1/embeddings \
     -H "Content-Type: application/json" \
     -d '{"input": "test", "model": "nomic-embed"}'
   ```

6. **vLLM Connectivity**:
   ```bash
   kubectl exec -n private-gpt -it deployment/private-gpt -- \
     curl -s http://vllm.inference.svc.cluster.local:8000/v1/models
   ```
   - Expect: JSON response with available models

7. **Storage Check**:
   ```bash
   kubectl get pvc -n private-gpt
   ```
   - Expect: PVC bound to PV

---

## 🎓 AGENT SUCCESS CRITERIA

**A successful interaction means**:

✅ **Deployment**:
- All manifests apply without errors
- Pod reaches Running state within 2 minutes
- Certificate issues successfully
- Application accessible via HTTPS

✅ **Integration**:
- vLLM service connectivity verified
- Document upload and ingestion works
- RAG query returns relevant responses
- API endpoints respond correctly

✅ **Code Quality**:
- Docker builds without warnings
- Health checks pass consistently
- Logs show no errors or warnings
- Resource usage within limits

✅ **Documentation**:
- Changes documented in appropriate files
- ChromaDB updated if platform integration changes
- README-K8S.md reflects current state

✅ **User Preferences Met**:
- No workarounds or temp fixes
- Complete, production-ready solution
- PowerShell scripts execute successfully
- End-to-end validation confirms functionality

---

## 📅 CHANGE HISTORY

### 2025-11-13 - Initial Kubernetes Deployment
- Created multi-stage Dockerfile with Poetry
- Implemented Kubernetes manifests with vLLM integration
- Configured persistent storage for documents and Qdrant
- Added SSL ingress with Let's Encrypt DNS-01
- Created deployment automation scripts (build-and-push.ps1, deploy.ps1)
- Documented platform integration via ChromaDB
- Set up health checks and resource limits
- Configured ConfigMap for vLLM endpoint

**Key Integrations**:
- vLLM service: http://vllm.inference.svc.cluster.local:8000/v1
- Storage: 10Gi OpenEBS hostpath PVC
- Ingress: https://privategpt.lab.hq.solidrust.net
- Embeddings: nomic-ai/nomic-embed-text-v1.5 (HuggingFace)
- Vector DB: Qdrant (embedded, on PVC)

---

**Last Updated**: 2025-11-13
**Maintained By**: Shaun Prince
**Agent**: Claude Code (Sonnet 4.5)
**Platform**: srt-hq-k8s Production Cluster
