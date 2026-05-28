#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# 01 — Install prerequisites for Nelm in Action
# ────────────────────────────────────────────────────────────────
set -euo pipefail

echo "⚓ Nelm in Action — Installing prerequisites"
echo "=============================================="

# Check Homebrew
if ! command -v brew &>/dev/null; then
  echo "❌ Homebrew is required. Install from https://brew.sh"
  exit 1
fi

# Check Docker
if ! command -v docker &>/dev/null; then
  echo "❌ Docker Desktop is required. Install from https://docker.com"
  exit 1
fi
if ! docker info &>/dev/null 2>&1; then
  echo "⚠️  Docker is installed but not running. Please start Docker Desktop."
  exit 1
fi
echo "✅ Docker is running"

install_if_missing() {
  local cmd=$1
  local formula=$2
  if command -v "$cmd" &>/dev/null; then
    echo "✅ $cmd already installed ($(command -v "$cmd"))"
  else
    echo "📦 Installing $formula …"
    brew install "$formula"
  fi
}

install_if_missing minikube minikube
install_if_missing kubectl kubernetes-cli

echo ""
echo "✅ All prerequisites installed."
echo ""
echo "Versions:"
echo "  minikube  $(minikube version --short 2>/dev/null || echo 'n/a')"
echo "  kubectl   $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)"
echo ""
echo "Next → ./scripts/02-start-cluster.sh"
