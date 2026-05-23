#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# 01 — Install prerequisites for Nelm in Action
# ────────────────────────────────────────────────────────────────
set -euo pipefail

echo "⚓ Nelm in Action — Installing prerequisites"
echo "=============================================="

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
