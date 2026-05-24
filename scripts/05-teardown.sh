#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# 05 — Teardown: remove everything
# ────────────────────────────────────────────────────────────────
set -euo pipefail
export PATH="${HOME}/.local/bin:${PATH}"

PROFILE="nelm-demo"
NS="nelm-demo"

echo "⚓ Nelm in Action — Teardown"
echo "=============================="

echo "🗑️  Uninstalling Nelm releases …"
nelm release uninstall -n "$NS" -r scores-api 2>/dev/null || true
nelm release uninstall -n "$NS" -r nginx-remote 2>/dev/null || true

echo "🗑️  Deleting namespace $NS …"
kubectl delete namespace "$NS" --ignore-not-found

echo "🗑️  Deleting Minikube profile '$PROFILE' …"
minikube delete -p "$PROFILE"

echo ""
echo "✅ Teardown complete — your system is clean."
