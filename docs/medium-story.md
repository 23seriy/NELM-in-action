# Meet Nelm: The Modern Helm Alternative You Didn't Know You Needed

If you've been working with Kubernetes for a while, you're undoubtedly familiar with Helm. It's the de-facto package manager for Kubernetes, used everywhere from small personal clusters to massive enterprise deployments. But despite its ubiquity, Helm has some long-standing rough edges: complicated resource tracking, lack of a robust `plan` feature, and frustrating bugs that have lingered for years.

Enter **[Nelm](https://github.com/werf/nelm)**.

Nelm is a Kubernetes deployment tool designed as a modern Helm 4 alternative. Originally developed as the deployment engine for [werf](https://github.com/werf/werf), it has been extracted into a standalone tool that handles everything Helm does, but better.

In this article, we'll explore what makes Nelm special and how to get started with it using a hands-on example.

## What makes Nelm different?

Nelm is built on top of an improved and partially rewritten Helm codebase. This means it maintains 100% backward compatibility with your existing Helm charts and releases, but introduces game-changing features:

1. **`terraform plan`-like Capabilities:** Before applying a change, you can see exactly what resources will be modified in the cluster using robust dry-run Server-Side Apply.
2. **Continuous Logging:** During deployment, Nelm streams the logs of your deploying pods directly to your terminal. No more switching contexts to run `kubectl logs` while waiting for a rollout.
3. **Advanced Resource Tracking:** It knows the exact state of your deployment, catching errors early and presenting them clearly.
4. **Out-of-the-box Secrets Management:** Encrypt and decrypt secrets natively without needing external plugins like `helm-secrets`.

## Seeing Nelm in Action

Let's take Nelm for a spin. I've created a sample repository, [nelm-in-action](https://github.com/solshanetski/nelm-in-action), to demonstrate its features locally.

### Step 1: Setup

First, let's spin up a local Kubernetes cluster using Minikube and install Nelm:

```bash
# Start Minikube
minikube start

# Install Nelm
curl -sL "https://github.com/werf/nelm/releases/latest/download/nelm-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')" -o nelm
chmod +x nelm
sudo mv nelm /usr/local/bin/nelm
```

### Step 2: Deploying a Chart

With Nelm, the syntax is familiar but improved. Let's deploy a standard chart:

```bash
nelm release install -n default -r my-nelm-demo ./charts/mychart
```

As this runs, you'll immediately notice the difference. Nelm provides real-time feedback, showing the exact resources being created and streaming the events and logs from the pods as they start up.

### Step 3: The Magic of `plan`

Now, let's see Nelm's killer feature. We want to scale our application from 1 to 3 replicas. With Helm, you'd run `helm upgrade` and hope for the best. With Nelm, you can *plan* it:

```bash
nelm release plan install -n default -r my-nelm-demo ./charts/mychart --set replicaCount=3
```

Nelm evaluates the cluster state and outputs a clear diff showing exactly what will change. It uses Server-Side Apply dry-runs, making it incredibly accurate. Once you're satisfied, you run the `install` command with the same parameters to execute the change.

## Conclusion

Nelm solves many of the daily frustrations DevOps engineers face when using Helm. By providing better visibility, real dry-runs, and maintaining compatibility with the vast ecosystem of existing Helm charts, it positions itself as a compelling upgrade.

If you want to try it yourself, clone the [nelm-in-action](https://github.com/solshanetski/nelm-in-action) repository and run the provided scripts. 

*Have you tried Nelm yet? Let me know your thoughts in the comments!*
