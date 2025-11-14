#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy PrivateGPT to Kubernetes cluster.

.DESCRIPTION
    Deploys PrivateGPT RAG application with vLLM integration to the srt-hq-k8s cluster.
    Supports build, push, deploy, and uninstall operations.

.PARAMETER Build
    Build the Docker image before deploying

.PARAMETER Push
    Push the Docker image to Docker Hub before deploying

.PARAMETER Uninstall
    Remove all PrivateGPT resources from the cluster

.EXAMPLE
    .\deploy.ps1
    Deploy using existing Docker Hub image

.EXAMPLE
    .\deploy.ps1 -Build -Push
    Build, push, and deploy

.EXAMPLE
    .\deploy.ps1 -Uninstall
    Remove all resources
#>

[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$Push,
    [switch]$Uninstall
)

#region Configuration
$ErrorActionPreference = "Stop"
$Namespace = "private-gpt"
$AppName = "private-gpt"
$ManifestsPath = Join-Path $PSScriptRoot "k8s"
#endregion

#region Functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    $previousColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $previousColor
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "`n==> $Message" -Color Cyan
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" -Color Green
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" -Color Red
}

function Test-KubernetesConnection {
    try {
        kubectl cluster-info | Out-Null
        return $true
    } catch {
        return $false
    }
}
#endregion

#region Main Script
Write-Step "PrivateGPT Kubernetes Deployment"

# Validate kubectl
if (-not (Test-KubernetesConnection)) {
    Write-Error "Cannot connect to Kubernetes cluster"
    exit 1
}
Write-Success "Connected to Kubernetes cluster"

# Handle uninstall
if ($Uninstall) {
    Write-Step "Uninstalling PrivateGPT"

    Write-Output "Deleting Kubernetes resources..."
    kubectl delete -f $ManifestsPath --ignore-not-found=true

    Write-Output "Waiting for namespace deletion..."
    kubectl wait --for=delete namespace/$Namespace --timeout=60s 2>$null

    Write-Success "PrivateGPT uninstalled successfully"
    exit 0
}

# Handle build
if ($Build) {
    Write-Step "Building Docker image"
    $buildArgs = @()
    if ($Push) {
        $buildArgs += "-Push"
    }
    & (Join-Path $PSScriptRoot "build-and-push.ps1") @buildArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed"
        exit 1
    }
}

# Deploy to Kubernetes
Write-Step "Deploying to Kubernetes"

Write-Output "Applying manifests from: $ManifestsPath"
kubectl apply -f $ManifestsPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed"
    exit 1
}
Write-Success "Manifests applied"

# Wait for rollout
Write-Step "Waiting for deployment rollout"
kubectl rollout status deployment/$AppName -n $Namespace --timeout=5m
if ($LASTEXITCODE -ne 0) {
    Write-Error "Rollout failed"
    Write-Output "`nCheck logs with:"
    Write-Output "  kubectl logs -n $Namespace -l app=$AppName --tail=50"
    exit 1
}
Write-Success "Deployment rolled out successfully"

# Display status
Write-Step "Deployment Status"

Write-Output "`n--- Pods ---"
kubectl get pods -n $Namespace -o wide

Write-Output "`n--- Service ---"
kubectl get service -n $Namespace

Write-Output "`n--- Ingress ---"
kubectl get ingress -n $Namespace

Write-Output "`n--- Certificate ---"
kubectl get certificate -n $Namespace

Write-Output "`n--- PersistentVolumeClaim ---"
kubectl get pvc -n $Namespace

# Check vLLM dependency
Write-Step "Checking vLLM Dependency"
$vllmStatus = kubectl get pods -n vllm-inference -l app=vllm -o jsonpath='{.items[0].status.phase}' 2>$null
if ($vllmStatus -eq "Running") {
    Write-Success "vLLM service is running"
} else {
    Write-ColorOutput "⚠ vLLM service may not be running. PrivateGPT requires vLLM for inference." -Color Yellow
    Write-Output "Check vLLM status:"
    Write-Output "  kubectl get pods -n vllm-inference"
}

# Summary
Write-Step "Deployment Summary"
Write-Output "Application: PrivateGPT RAG with vLLM"
Write-Output "Namespace: $Namespace"
Write-Output "URL: https://privategpt.lab.hq.solidrust.net"
Write-Output ""
Write-Output "The certificate may take 1-2 minutes to issue."
Write-Output ""

Write-Success "Deployment complete!"

Write-Output "`n--- Useful Commands ---"
Write-Output "View logs:"
Write-Output "  kubectl logs -n $Namespace -l app=$AppName -f"
Write-Output ""
Write-Output "Check certificate:"
Write-Output "  kubectl get certificate -n $Namespace"
Write-Output ""
Write-Output "Describe pod:"
Write-Output "  kubectl describe pod -n $Namespace -l app=$AppName"
Write-Output ""
Write-Output "Update deployment:"
Write-Output "  .\deploy.ps1 -Build -Push"
Write-Output ""
Write-Output "Uninstall:"
Write-Output "  .\deploy.ps1 -Uninstall"
#endregion
