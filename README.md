# ⚓ Nelm in Action

A hands-on project demonstrating **[Nelm](https://github.com/werf/nelm)** — the modern Helm 4 alternative — on a local Minikube cluster. Built with a simple NBA Scores API to showcase `terraform plan`-like diffs, continuous deployment logging, save/apply plan workflows, auto-rollback, and more — all running on your laptop.

![Nelm](https://img.shields.io/badge/Nelm-latest-4A90D9?logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30+-326CE5?logo=kubernetes&logoColor=white)
![Minikube](https://img.shields.io/badge/Minikube-local-F7B93E?logo=kubernetes&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)

> 📝 **Read the full walkthrough on Medium:** [Nelm in Action: The Modern Helm Alternative on Your Laptop](https://medium.com/@sergeiolshanetski/nelm-in-action-the-modern-helm-alternative-on-your-laptop-564f976c3e2a)

## 🏗️ Architecture

```text
                    ┌──────────────────────────────────────────────┐
                    │              Minikube Cluster                 │
                    │              (nelm-demo profile)              │
                    │                                              │
  NBA Fan ────────► │  ┌─────────────────┐   ┌─────────────────┐  │
  localhost:9080    │  │  Scores API v1   │   │  Scores API v2  │  │
                    │  │  (basic scores)  │   │  (+ play-by-play)│  │
                    │  └────────┬────────┘   └────────┬────────┘  │
                    │           │                      │           │
                    │     Nelm Deployment Engine                    │
                    │     ─────────────────────                    │
                    │     📋 plan  → see diffs before deploying    │
                    │     🚀 install → deploy with live logging    │
                    │     💾 save-plan → review → apply later      │
                    │     ↩️  auto-rollback → revert on failure     │
                    │                                              │
                    │  ┌──────────────┐   ┌───────────────────┐   │
                    │  │  ConfigMap   │   │  Secret Values    │   │
                    │  │  (welcome)   │   │  (encrypted)      │   │
                    │  └──────────────┘   └───────────────────┘   │
                    └──────────────────────────────────────────────┘
```

**Scores API v1** — Returns basic NBA box scores (team, score, quarter, arena). The stable "production" version.

**Scores API v2** — Same box scores **plus live play-by-play** data (player actions, timestamps). The new version you deploy and plan against.

## 📋 What You'll Learn

| Nelm Feature | What It Does | Demo Scenario |
|---|---|---|
| **Plan (terraform plan)** | See exact resource diffs before deploying | Scale replicas, change image tag — review diff first |
| **Save Plan → Apply Plan** | Two-stage deployment: save to file, apply later | `--save-plan=plan.gz` then `--use-plan=plan.gz` |
| **Continuous Logging** | Stream pod logs and events during deployment | Watch real-time output as pods start |
| **Auto-Rollback** | Automatically revert on deployment failure | Deploy broken image → Nelm rolls back |
| **Chart Render** | Template rendering (like `helm template`) | Render chart locally without deploying |
| **Remote Charts** | Deploy charts from remote repos directly | Plan install of `bitnami/nginx` from OCI registry |
| **Release List** | List all managed releases | Native Nelm implementation of `helm list` |
| **Helm Compatibility** | Deploy standard Helm charts unchanged | Our chart uses standard `Chart.yaml` + `templates/` |

## 🚀 Quick Start

### Step 0: Clone the Repository

```bash
git clone https://github.com/23seriy/nelm-in-action.git
cd nelm-in-action
```

### Prerequisites

- **macOS** (scripts use Homebrew; adapt for Linux)
- **Docker Desktop** running
- ~4 GB RAM available for the Minikube cluster

### Step 1: Install Tools

```bash
chmod +x scripts/*.sh
./scripts/01-install-prerequisites.sh
```

This installs `minikube` and `kubectl` via Homebrew if not already present.

### Step 2: Start Cluster + Install Nelm

```bash
./scripts/02-start-cluster.sh
```

Creates a Minikube cluster (`nelm-demo` profile) with 2 CPUs and 4 GB RAM, then downloads and installs the Nelm CLI to `~/.local/bin`.

> **Note:** If you want to run `nelm` commands directly in your terminal (outside the scripts), make sure `~/.local/bin` is on your PATH:
> ```bash
> export PATH="${HOME}/.local/bin:${PATH}"
> ```
> Add the line above to your `~/.zshrc` (or `~/.bashrc`) to make it permanent.

### Step 3: Build & Deploy the Application

```bash
./scripts/03-deploy.sh
```

Builds Docker images inside Minikube's Docker daemon (no registry needed), creates the namespace, and deploys the Scores API using `nelm release install`. Watch the continuous logging in action.

### Step 4: Access the Application

In a **separate terminal**:

```bash
kubectl port-forward svc/scores-api 9080:8080 -n nelm-demo
```

Open **http://localhost:9080** to see the Scores API.

### Step 5: Run the Demo Scenarios

```bash
./scripts/04-demo-scenarios.sh
```

This walks you through each Nelm feature interactively.

## 🎮 Demo Scenarios

### 1. Plan — terraform plan for Kubernetes

```bash
nelm release plan install -n nelm-demo -r scores-api ./charts/scores-api \
  --set replicaCount=3 --set image.tag=v2
```

See the exact diff: replica count change, image tag update, configmap modification — all shown before anything touches the cluster. Uses Server-Side Apply dry-runs for accuracy.

### 2. Save Plan → Review → Apply Plan

```bash
# Save the plan
nelm release plan install -n nelm-demo -r scores-api ./charts/scores-api \
  --set replicaCount=2 --save-plan=plan.gz

# Review, then apply
nelm release install -n nelm-demo -r scores-api ./charts/scores-api \
  --use-plan=plan.gz
```

Two-stage deployment workflow, just like `terraform plan -out=plan.gz` + `terraform apply plan.gz`.

### 3. Continuous Logging During Deploy

```bash
nelm release install -n nelm-demo -r scores-api ./charts/scores-api \
  --set config.welcomeMessage="Hello from Nelm!"
```

Nelm streams pod logs and Kubernetes events in real-time as the deployment rolls out. The `werf.io/show-service-messages: "true"` annotation enables event streaming.

### 4. Chart Render

```bash
nelm chart render ./charts/scores-api --set replicaCount=5 --set image.tag=v2
```

Equivalent to `helm template`. Renders the chart locally and outputs the resulting manifests.

### 5. Deploy a Remote Chart

```bash
NELM_FEAT_REMOTE_CHARTS=true nelm release plan install -n nelm-demo -r nginx-remote \
  --chart-version 19.1.1 oci://registry-1.docker.io/bitnamicharts/nginx
```

Deploy charts directly from remote OCI registries. No `helm repo add` needed. Remote chart support requires the `NELM_FEAT_REMOTE_CHARTS=true` feature flag.

### 6. Auto-Rollback on Failure

```bash
nelm release install -n nelm-demo -r scores-api ./charts/scores-api \
  --auto-rollback --resource-readiness-timeout=30s --values nelm/values-broken.yaml
```

Deploy a broken image intentionally. Nelm detects the failure within the readiness timeout and automatically reverts to the previous working state. Like `helm upgrade --atomic`, but more reliable.

> **Tip:** Use `--resource-readiness-timeout` (not `--timeout`) with `--auto-rollback`. The global `--timeout` kills the entire process without triggering rollback, while `--resource-readiness-timeout` fails the readiness check and lets the rollback logic run.

## 📁 Project Structure

```text
nelm-in-action/
├── apps/
│   └── scores-api/              # NBA Scores API (Flask)
│       ├── app.py               # v1: basic scores, v2: + play-by-play
│       ├── Dockerfile
│       └── requirements.txt
├── charts/
│   └── scores-api/              # Helm chart (standard, Nelm-compatible)
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── configmap.yaml
│           ├── deployment.yaml  # werf.io/show-service-messages annotation
│           └── service.yaml
├── k8s/                         # Kubernetes manifests
│   └── namespace.yaml
├── nelm/                        # Nelm-specific value overrides
│   ├── values-v2-upgrade.yaml   # Upgrade to v2 with play-by-play
│   ├── values-scale-up.yaml     # Scale to 5 replicas + more resources
│   └── values-broken.yaml       # Broken image for auto-rollback demo
├── scripts/                     # Automation scripts
│   ├── 01-install-prerequisites.sh
│   ├── 02-start-cluster.sh
│   ├── 03-deploy.sh
│   ├── 04-demo-scenarios.sh
│   └── 05-teardown.sh
├── docs/
│   └── medium-story.md          # Medium article draft
└── .gitignore
```

## 🧹 Teardown

```bash
./scripts/05-teardown.sh
```

Uninstalls all Nelm releases, deletes the namespace, and removes the Minikube cluster. Your system is back to clean state.

## 💡 Key Takeaways

1. **Plan before you deploy** — `nelm release plan install` shows the exact diff of what will change, using Server-Side Apply dry-runs. No more "deploy and hope" — you see the impact before committing.

2. **Two-stage deployments** — Save a plan to a file, pass it through a review/approval gate, then apply it. This brings the terraform workflow to Kubernetes.

3. **Real-time visibility** — Nelm streams pod logs and events during deployment. No more switching terminals to run `kubectl logs` while waiting for a rollout.

4. **Automatic rollback** — `--auto-rollback` reverts to the previous state on failure, more reliably than Helm's `--atomic`.

5. **Zero migration cost** — Nelm deploys standard Helm charts unchanged. It uses Helm Releases for state, so you can switch between Helm and Nelm interchangeably.

6. **Built-in secrets** — `nelm chart secret` manages encrypted values files natively, no external plugins needed.

## ⚡ Helm → Nelm Migration Cheatsheet

| Helm Command | Nelm Equivalent |
|---|---|
| `helm upgrade --install --atomic -n ns myrls ./chart` | `nelm release install --auto-rollback -n ns -r myrls ./chart` |
| `helm uninstall -n ns myrls` | `nelm release uninstall -n ns -r myrls` |
| `helm template ./chart` | `nelm chart render ./chart` |
| `helm dependency build` | `nelm chart dependency download` |
| `helm list` | `nelm release list` |
| *(no equivalent)* | `nelm release plan install` |
| *(needs helm-secrets plugin)* | `nelm chart secret values-file edit` |

## 📚 Resources

- [Nelm Repository](https://github.com/werf/nelm) — Source code and documentation
- [werf](https://github.com/werf/werf) — The CI/CD tool that Nelm powers
- [Helm Documentation](https://helm.sh/docs/) — For comparison with Nelm features
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## 📝 License

MIT — Use freely for learning, demos, and presentations.
