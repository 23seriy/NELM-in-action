# Nelm in Action

This project demonstrates the main features of [Nelm](https://github.com/werf/nelm), the modern Helm 4 alternative. 

It provides hands-on scripts and a sample chart to easily test Nelm locally using Minikube.

## Directory Structure

- `charts/mychart`: A sample Helm chart.
- `scripts/`: Shell scripts to setup, deploy, and clean up the demo.
- `docs/`: Additional documentation and articles (e.g., Medium story draft).

## Getting Started

1. **Setup the cluster**
   Run the `01-setup-cluster.sh` script to spin up a Minikube cluster:
   ```bash
   ./scripts/01-setup-cluster.sh
   ```

2. **Install Nelm**
   Download and install the latest `nelm` release:
   ```bash
   ./scripts/02-install-nelm.sh
   ```

3. **Deploy with Nelm**
   Install the release and watch Nelm's real-time continuous logging:
   ```bash
   ./scripts/03-deploy.sh
   ```

4. **Plan an Update**
   Test Nelm's powerful `terraform plan`-like capability by updating the replica count:
   ```bash
   ./scripts/04-plan.sh
   ```

5. **Cleanup**
   When you're done, uninstall the release and delete the Minikube cluster:
   ```bash
   ./scripts/05-cleanup.sh
   ```

## Key Nelm Features Showcased
- **Continuous Logging:** You'll see real-time log output and event streaming during `nelm release install`.
- **Plan Capability:** `nelm release plan install` allows you to see the exact Server-Side Apply diff before committing to changes in the cluster.
- **Backward Compatibility:** We are deploying a standard Helm chart structure (`Chart.yaml`, `values.yaml`, `templates/`) without any modifications.

## Further Reading
- Check out the [Medium Story Draft](./docs/medium-story.md) included in this repository.
- Read more about Nelm in the official [Nelm repository](https://github.com/werf/nelm).
