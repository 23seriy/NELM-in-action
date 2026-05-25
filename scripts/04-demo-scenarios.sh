#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# 04 — Interactive demo scenarios for Nelm
# ────────────────────────────────────────────────────────────────
set -euo pipefail
export PATH="${HOME}/.local/bin:${PATH}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
NS="nelm-demo"

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

banner() { echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════════${NC}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${CYAN}${BOLD}══════════════════════════════════════════════${NC}\n"; }
info()   { echo -e "${GREEN}▸ $1${NC}"; }
warn()   { echo -e "${YELLOW}▸ $1${NC}"; }

wait_for_enter() {
  echo ""
  read -rp "Press ENTER to continue …"
  echo ""
}

echo "⚓ Nelm in Action — Demo Scenarios"
echo "====================================="
echo ""
echo "Make sure you have port-forwarding running in a separate terminal:"
echo "  kubectl port-forward svc/scores-api 9080:8080 -n $NS"
echo ""
echo "App: http://localhost:9080"

wait_for_enter

# ══════════════════════════════════════════════════════════════
# Scenario 1: Plan — See what would change (terraform plan)
# ══════════════════════════════════════════════════════════════
banner "Scenario 1: Plan — terraform plan for Kubernetes"
info "Nelm's killer feature: see exactly what will change BEFORE applying."
info "We'll scale from 1 to 3 replicas and change the image tag."
echo ""
info "Running: nelm release plan install …"
echo ""
nelm release plan install -n "$NS" -r scores-api "$PROJECT_DIR/charts/scores-api" \
  --set replicaCount=3 \
  --set image.tag=v2 || true
echo ""
warn "Above you can see the exact diff of what would change in the cluster."
warn "Nothing has been applied yet — this is a dry-run using Server-Side Apply."

wait_for_enter

# ══════════════════════════════════════════════════════════════
# Scenario 2: Save Plan + Apply Plan
# ══════════════════════════════════════════════════════════════
banner "Scenario 2: Save Plan → Review → Apply Plan"
info "Like 'terraform plan -out=plan.gz' + 'terraform apply plan.gz'"
info "Two-stage deployment: save the plan, then apply it later."
echo ""
info "Step 1: Save the plan to a file …"
nelm release plan install -n "$NS" -r scores-api "$PROJECT_DIR/charts/scores-api" \
  --set replicaCount=2 \
  --save-plan=/tmp/nelm-plan.gz || true
echo ""
info "Plan saved to /tmp/nelm-plan.gz"
info "Step 2: Apply the saved plan …"
echo ""
nelm release install -n "$NS" -r scores-api "$PROJECT_DIR/charts/scores-api" \
  --use-plan=/tmp/nelm-plan.gz || {
    warn "save-plan/use-plan requires Nelm v1+. Falling back to direct install …"
    nelm release install -n "$NS" -r scores-api "$PROJECT_DIR/charts/scores-api" \
      --set replicaCount=2
  }
echo ""
info "Verifying the update:"
kubectl get pods -n "$NS"

wait_for_enter

# ══════════════════════════════════════════════════════════════
# Scenario 3: Continuous Logging
# ══════════════════════════════════════════════════════════════
banner "Scenario 3: Continuous Logging During Deploy"
info "Nelm streams pod logs and events during deployment."
info "The 'werf.io/show-service-messages' annotation enables event streaming."
info "We'll update the configmap and redeploy to see logs in action."
echo ""
info "Deploying with updated welcome message …"
nelm release install -n "$NS" -r scores-api "$PROJECT_DIR/charts/scores-api" \
  --set replicaCount=2 \
  --set config.welcomeMessage="Hello from Nelm Demo - Updated!" || true
echo ""
info "Notice the real-time pod logs and events printed above."

wait_for_enter

# ══════════════════════════════════════════════════════════════
# Scenario 4: Chart Render (helm template equivalent)
# ══════════════════════════════════════════════════════════════
banner "Scenario 4: Chart Render (helm template equivalent)"
info "nelm chart render = helm template, but with Nelm improvements."
echo ""
nelm chart render "$PROJECT_DIR/charts/scores-api" \
  --set replicaCount=5 \
  --set image.tag=v2 2>/dev/null | head -80 || true
echo ""
warn "(Output truncated to 80 lines for readability)"

wait_for_enter

# ══════════════════════════════════════════════════════════════
# Scenario 5: Deploy a Remote Chart
# ══════════════════════════════════════════════════════════════
banner "Scenario 5: Deploy a Remote Chart"
info "Nelm can deploy charts directly from remote repositories."
info "No need to helm repo add + helm pull first."
echo ""
info "Planning a remote nginx chart install …"
info "(Requires NELM_FEAT_REMOTE_CHARTS=true feature flag)"
NELM_FEAT_REMOTE_CHARTS=true nelm release plan install -n "$NS" -r nginx-remote \
  --chart-version 19.1.1 oci://registry-1.docker.io/bitnamicharts/nginx 2>/dev/null || \
  warn "Remote chart plan requires network access. Skipping if offline."

wait_for_enter

# ══════════════════════════════════════════════════════════════
# Scenario 6: Release List
# ══════════════════════════════════════════════════════════════
banner "Scenario 6: Release List"
info "nelm release list = helm list, native Nelm implementation."
echo ""
nelm release list -n "$NS" 2>/dev/null || \
nelm release list 2>/dev/null || \
  warn "release list not available in this version."

wait_for_enter

# ══════════════════════════════════════════════════════════════
# Scenario 7: Auto-Rollback
# ══════════════════════════════════════════════════════════════
banner "Scenario 7: Auto-Rollback on Failure"
info "nelm release install --auto-rollback reverts on deploy failure."
info "Like 'helm upgrade --atomic' but more reliable."
echo ""
info "Deploying with a deliberately broken image to trigger rollback …"
nelm release install -n "$NS" -r scores-api "$PROJECT_DIR/charts/scores-api" \
  --auto-rollback \
  --resource-readiness-timeout=30s \
  --set image.repository=nginx \
  --set image.tag=does-not-exist \
  --set image.pullPolicy=Never 2>&1 || true
echo ""
info "Nelm detected the failure and rolled back. Checking current state:"
kubectl get pods -n "$NS"

wait_for_enter

# ══════════════════════════════════════════════════════════════
banner "🎉 All Scenarios Complete!"
echo ""
info "Restore to clean state:"
echo "  nelm release install -n $NS -r scores-api $PROJECT_DIR/charts/scores-api"
echo ""
info "Run ./scripts/05-teardown.sh to clean up when done."
echo ""
