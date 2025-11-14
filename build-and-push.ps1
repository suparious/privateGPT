#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build and push PrivateGPT Docker image to Docker Hub.

.DESCRIPTION
    Builds the PrivateGPT Docker image with Poetry dependencies and optionally pushes to Docker Hub.
    Supports cross-platform execution (WSL2 + Windows).

.PARAMETER Login
    Authenticate with Docker Hub before building

.PARAMETER Push
    Push the image to Docker Hub after building

.PARAMETER Tag
    Custom tag for the image (default: latest)

.EXAMPLE
    .\build-and-push.ps1
    Build image locally

.EXAMPLE
    .\build-and-push.ps1 -Login -Push
    Build and push image to Docker Hub
#>

[CmdletBinding()]
param(
    [switch]$Login,
    [switch]$Push,
    [string]$Tag = "latest"
)

#region Configuration
$ErrorActionPreference = "Stop"
$ImageName = "suparious/private-gpt"
$ImageTag = "${ImageName}:${Tag}"

# Cross-platform path handling
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $RepoPath = "C:\Users\shaun\repos\privateGPT"
} else {
    $RepoPath = "/mnt/c/Users/shaun/repos/privateGPT"
}

# Copy Dockerfile to repo for build context
$DockerfilePath = Join-Path $PSScriptRoot "Dockerfile"
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

function Test-DockerRunning {
    try {
        docker info | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-DockerHubLogin {
    $username = docker info 2>&1 | Select-String "Username:" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    return $username -eq "suparious"
}
#endregion

#region Main Script
Write-Step "PrivateGPT Docker Build Script"
Write-Output "Image: $ImageTag"
Write-Output "Repository: $RepoPath"

# Validate Docker
if (-not (Test-DockerRunning)) {
    Write-Error "Docker is not running"
    exit 1
}
Write-Success "Docker is running"

# Handle Docker Hub login
if ($Login) {
    Write-Step "Logging into Docker Hub"
    docker login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker login failed"
        exit 1
    }
    Write-Success "Logged into Docker Hub"
}

# Check authentication if pushing
if ($Push -and -not (Test-DockerHubLogin)) {
    Write-Error "Not logged into Docker Hub as 'suparious'. Run with -Login flag first."
    exit 1
}

# Validate repository path
if (-not (Test-Path $RepoPath)) {
    Write-Error "Repository not found at: $RepoPath"
    exit 1
}

# Copy Dockerfile to repository
Write-Step "Copying Dockerfile to repository"
Copy-Item -Path $DockerfilePath -Destination (Join-Path $RepoPath "Dockerfile") -Force
Write-Success "Dockerfile copied"

# Build image
Write-Step "Building Docker image"
Push-Location $RepoPath
try {
    docker build -t $ImageTag .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed"
        exit 1
    }
    Write-Success "Image built successfully"
} finally {
    Pop-Location
}

# Test image
Write-Step "Testing Docker image"
$testContainer = docker run -d -p 8091:8001 $ImageTag
if ($LASTEXITCODE -eq 0) {
    Write-Output "Container started: $testContainer"
    Write-Output "Waiting for application to start..."
    Start-Sleep -Seconds 10

    # Cleanup test container
    docker stop $testContainer | Out-Null
    docker rm $testContainer | Out-Null
    Write-Success "Image test completed"
} else {
    Write-Error "Failed to start test container"
    exit 1
}

# Push image
if ($Push) {
    Write-Step "Pushing image to Docker Hub"
    docker push $ImageTag
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker push failed"
        exit 1
    }
    Write-Success "Image pushed successfully"
}

# Summary
Write-Step "Build Summary"
Write-Output "Image: $ImageTag"
Write-Output "Size: $(docker images $ImageName --format '{{.Size}}' | Select-Object -First 1)"

if ($Push) {
    Write-Success "Image available at: https://hub.docker.com/r/$ImageName"
} else {
    Write-Output "`nTo push image, run:"
    Write-Output "  .\build-and-push.ps1 -Login -Push"
}

Write-Output "`nTo run locally:"
Write-Output "  docker run -p 8001:8001 $ImageTag"

Write-Success "Build complete!"
#endregion
