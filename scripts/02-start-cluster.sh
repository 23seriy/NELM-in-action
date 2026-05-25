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
NELM_VERSION="${NELM_VERSION:-1.24.1}"

echo ""
if command -v nelm &>/dev/null; then
  echo "✅ nelm already installed ($(command -v nelm))"
else
  echo "📦 Installing Nelm CLI v${NELM_VERSION} …"
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi
  if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi

  NELM_URL="https://tuf.nelm.sh/targets/releases/${NELM_VERSION}/${OS}-${ARCH}/bin/nelm"
  INSTALL_DIR="${HOME}/.local/bin"
  mkdir -p "${INSTALL_DIR}"
  echo "   Downloading from ${NELM_URL}"
  curl -fsSL "${NELM_URL}" -o "${INSTALL_DIR}/nelm"
  chmod +x "${INSTALL_DIR}/nelm"
  echo "✅ Nelm v${NELM_VERSION} installed to ${INSTALL_DIR}/nelm"

  # Ensure ~/.local/bin is on PATH for the current session
  if ! echo "$PATH" | grep -q "${INSTALL_DIR}"; then
    export PATH="${INSTALL_DIR}:${PATH}"
    echo "   ℹ️  Added ${INSTALL_DIR} to PATH for this session."
    echo "   To make it permanent, add to your shell profile:"
    echo "     export PATH=\"\${HOME}/.local/bin:\${PATH}\""
  fi
fi

echo ""
echo "Versions:"
echo "  nelm      $(nelm version 2>/dev/null || echo 'installed')"
echo "  minikube  $(minikube version --short 2>/dev/null || echo 'n/a')"
echo ""
kubectl get nodes
echo ""
echo "Next → ./scripts/03-deploy.sh"
