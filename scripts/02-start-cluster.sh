#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# 02 — Start Minikube cluster + install Nelm CLI
# ────────────────────────────────────────────────────────────────
set -euo pipefail

PROFILE="nelm-demo"
K8S_VERSION="v1.30.0"

echo "⚓ Nelm in Action — Starting cluster"
echo "======================================"

# ── Minikube ──────────────────────────────────────────────────
if minikube status -p "$PROFILE" &>/dev/null; then
  echo "✅ Minikube profile '$PROFILE' is already running."
else
  echo "🚀 Creating Minikube cluster (profile=$PROFILE, k8s=$K8S_VERSION) …"
  minikube start \
    -p "$PROFILE" \
    --kubernetes-version="$K8S_VERSION" \
    --cpus=2 \
    --memory=4g \
    --driver=docker
fi

# Make sure kubectl context points at our profile
minikube update-context -p "$PROFILE"
echo "📌 kubectl context set to $PROFILE"

# ── Install Nelm CLI ──────────────────────────────────────────
echo ""
if command -v nelm &>/dev/null; then
  echo "✅ nelm already installed ($(command -v nelm))"
else
  echo "📦 Installing Nelm CLI …"
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi
  if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi

  curl -fsSL "https://github.com/werf/nelm/releases/latest/download/nelm-${OS}-${ARCH}" -o /tmp/nelm
  chmod +x /tmp/nelm
  sudo mv /tmp/nelm /usr/local/bin/nelm
  echo "✅ Nelm installed to /usr/local/bin/nelm"
fi

echo ""
echo "Versions:"
echo "  nelm      $(nelm version 2>/dev/null || echo 'installed')"
echo "  minikube  $(minikube version --short 2>/dev/null || echo 'n/a')"
echo ""
kubectl get nodes
echo ""
echo "Next → ./scripts/03-deploy.sh"
