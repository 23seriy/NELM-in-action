#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# 03 — Build images & deploy the app with Nelm
# ────────────────────────────────────────────────────────────────
set -euo pipefail

PROFILE="nelm-demo"
NS="nelm-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "⚓ Nelm in Action — Build & Deploy"
echo "====================================="

# ── Point Docker at Minikube ──────────────────────────────────
echo "🐳 Configuring Docker to use Minikube daemon …"
eval "$(minikube docker-env -p "$PROFILE")"

# ── Build the demo app ────────────────────────────────────────
echo ""
echo "🔨 Building scores-api:v1 …"
docker build \
  --build-arg APP_VERSION=v1 \
  -t scores-api:v1 \
  "$PROJECT_DIR/apps/scores-api"

echo "🔨 Building scores-api:v2 …"
docker build \
  --build-arg APP_VERSION=v2 \
  -t scores-api:v2 \
  "$PROJECT_DIR/apps/scores-api"

# ── Create namespace ──────────────────────────────────────────
echo ""
echo "📁 Creating namespace …"
kubectl apply -f "$PROJECT_DIR/k8s/namespace.yaml"

# ── Deploy with Nelm ─────────────────────────────────────────
echo ""
echo "🚀 Deploying with Nelm (release install) …"
echo "   Watch the real-time logs and events that Nelm streams below:"
echo ""
nelm release install -n "$NS" -r scores-api "$PROJECT_DIR/charts/scores-api"

echo ""
echo "✅ Deployment complete!"
echo ""
kubectl get all -n "$NS"
echo ""
echo "────────────────────────────────────────────"
echo "Access the app:"
echo "  kubectl port-forward svc/scores-api 9080:8080 -n $NS"
echo "  open http://localhost:9080"
echo ""
echo "Next → ./scripts/04-demo-scenarios.sh"
