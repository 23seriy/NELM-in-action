# Nelm in Action: The Modern Helm Alternative on Your Laptop

*A hands-on guide to deploying Kubernetes applications with Nelm — terraform plan for Helm, continuous logging, auto-rollback, and built-in secrets.*

---

If you've been working with Kubernetes for a while, you've probably experienced this: you run `helm upgrade`, stare at a blinking cursor, and wonder what's actually happening inside the cluster. Did the pod start? Is it crashing? Are the resources correct? You switch terminals, run `kubectl get pods -w` in one, `kubectl logs -f` in another, and piece together the story.

What if your deployment tool just... told you?

Enter **[Nelm](https://github.com/werf/nelm)**.

## What is Nelm?

Nelm is a Kubernetes deployment tool built as a modern Helm 4 alternative. Originally the deployment engine behind [werf](https://github.com/werf/werf) (battle-tested across thousands of projects), it has been extracted into a standalone tool.

The key insight: Nelm is **backward-compatible** with your existing Helm charts and releases. You can deploy the same release with Helm and Nelm interchangeably — no migration needed. But Nelm fixes hundreds of Helm bugs and adds features that Helm simply doesn't have.

## Why Should You Care?

Here's what Nelm does that Helm doesn't:

| Feature | Helm | Nelm |
|---|---|---|
| See changes before deploying | ❌ `--dry-run` is inaccurate | ✅ Server-Side Apply dry-run |
| Save plan, apply later | ❌ | ✅ `--save-plan` / `--use-plan` |
| Real-time pod logs during deploy | ❌ | ✅ Built-in |
| Secrets management | ❌ (needs plugin) | ✅ Native `nelm chart secret` |
| Resource ordering (DAG) | ❌ Sequential only | ✅ Directed Acyclic Graph |
| State tracking | Basic | Advanced error/status detection |

Let me walk you through each of these with a real example.

## Setting Up the Demo

I've created a repository — [nelm-in-action](https://github.com/23seriy/nelm-in-action) — with everything you need to follow along. It includes a simple NBA Scores API, a Helm chart, and scripts that automate the setup.

```bash
git clone https://github.com/23seriy/nelm-in-action.git
cd nelm-in-action

# Install prerequisites (minikube, kubectl)
./scripts/01-install-prerequisites.sh

# Start Minikube cluster + install Nelm CLI
./scripts/02-start-cluster.sh

# Build images + deploy with Nelm
./scripts/03-deploy.sh
```

The `02-start-cluster.sh` script downloads the Nelm binary from [tuf.nelm.sh](https://tuf.nelm.sh) and installs it to `~/.local/bin/` — no `sudo` required. If you want to run `nelm` commands directly in your terminal (outside the scripts), make sure `~/.local/bin` is on your PATH:

```bash
export PATH="${HOME}/.local/bin:${PATH}"
```

After the deploy script runs, you'll notice something immediately different from Helm: **Nelm printed the pod logs and Kubernetes events in real-time** as the deployment progressed. No separate terminal needed.

## Feature 1: `terraform plan` for Kubernetes

This is Nelm's killer feature. Say we want to scale from 1 to 3 replicas and upgrade from v1 to v2:

```bash
nelm release plan install -n nelm-demo -r scores-api ./charts/scores-api \
  --set replicaCount=3 --set image.tag=v2
```

Nelm outputs a clear diff showing:
- The Deployment's `replicas` field changing from `1` to `3`
- The container image changing from `scores-api:v1` to `scores-api:v2`
- The ConfigMap remaining unchanged

**Nothing touches the cluster.** This uses Kubernetes Server-Side Apply in dry-run mode, so the diffs are accurate — unlike Helm's `--dry-run` which doesn't account for server-side defaults and mutations.

If you're happy with the diff, apply it:

```bash
nelm release install -n nelm-demo -r scores-api ./charts/scores-api \
  --set replicaCount=3 --set image.tag=v2
```

## Feature 2: Save Plan → Review → Apply

For production workflows, you want separation between "what will change" and "do the change." Nelm supports this:

```bash
# Step 1: Generate and save the plan
nelm release plan install -n nelm-demo -r scores-api ./charts/scores-api \
  --set replicaCount=2 --save-plan=plan.gz

# Step 2: (Review the plan, get approval, run in CI...)

# Step 3: Apply the exact plan
nelm release install -n nelm-demo -r scores-api ./charts/scores-api \
  --use-plan=plan.gz
```

This is exactly the `terraform plan -out=plan.gz` + `terraform apply plan.gz` workflow, brought to Kubernetes deployments.

## Feature 3: Continuous Logging

When Nelm deploys, it finds pods of the deploying resources and periodically prints their container logs. With the `werf.io/show-service-messages: "true"` annotation on your pods, Kubernetes events are also streamed.

Our demo chart has this annotation:

```yaml
template:
  metadata:
    annotations:
      werf.io/show-service-messages: "true"
```

During deployment, you see output like:

```
┌ Deployment/scores-api
│ ↑ 1/1 replicas ready
│ Pod/scores-api-xxx-yyy container/scores-api:
│   * Running on http://0.0.0.0:8080
└ Ready
```

No more switching between terminals.

## Feature 4: Auto-Rollback

Helm has `--atomic`, but it's known to be unreliable in edge cases. Nelm's `--auto-rollback` is rebuilt from scratch:

```bash
# Deploy a broken image — Nelm will detect the failure and revert
nelm release install -n nelm-demo -r scores-api ./charts/scores-api \
  --auto-rollback --values nelm/values-broken.yaml
```

Nelm detects the failed rollout, outputs the error clearly, and automatically restores the previous working release.

## Feature 5: Remote Charts

With Helm, you need to `helm repo add`, `helm repo update`, then `helm install`. Nelm simplifies this:

```bash
NELM_FEAT_REMOTE_CHARTS=true nelm release plan install -n nelm-demo -r nginx-remote \
  --chart-version 19.1.1 oci://registry-1.docker.io/bitnamicharts/nginx
```

One command. No repo management.

> **Note:** Remote chart support and the `--chart-version` flag are currently behind the `NELM_FEAT_REMOTE_CHARTS=true` feature flag in Nelm v1.24.x.

## Migrating from Helm

The migration is straightforward — it's mostly renaming commands:

| Helm | Nelm |
|---|---|
| `helm upgrade --install --atomic` | `nelm release install --auto-rollback` |
| `helm uninstall` | `nelm release uninstall` |
| `helm template` | `nelm chart render` |
| `helm dependency build` | `nelm chart dependency download` |
| `helm list` | `nelm release list` |
| `helm install -f values.yaml` | `nelm release install --values values.yaml` |

> **Heads up:** Nelm uses `--values` instead of Helm's `-f` shorthand for additional values files. Most other flags map directly.

Since Nelm uses Helm Releases for state storage, you can literally swap the command in your CI pipeline and everything keeps working. No state migration, no downtime.

## When Should You Use Nelm?

**Use Nelm if:**
- You want to see what will change before deploying (the plan feature alone is worth it)
- You're tired of switching terminals to check pod logs during rollouts
- You need built-in secrets management without plugins
- You want more reliable auto-rollback
- You're already using Helm and want a drop-in improvement

**Keep using Helm if:**
- You rely heavily on Helm plugins (Nelm doesn't support the plugin API)
- You need the absolute widest community support and documentation

## Try It Yourself

Clone the [nelm-in-action](https://github.com/23seriy/nelm-in-action) repository and run `./scripts/04-demo-scenarios.sh` to walk through all 7 scenarios interactively. The whole demo runs on Minikube — nothing touches your production clusters.

```bash
git clone https://github.com/23seriy/nelm-in-action.git
cd nelm-in-action
chmod +x scripts/*.sh
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
./scripts/03-deploy.sh
./scripts/04-demo-scenarios.sh
```

The teardown script cleans everything up:

```bash
./scripts/05-teardown.sh
```

---

*Nelm is open source and actively developed. Check out the [GitHub repository](https://github.com/werf/nelm) for the latest features and roadmap.*

*What do you think — is `plan` enough reason to switch from Helm? Let me know in the comments.*
