#!/bin/bash
set -e

echo "Deploying with Nelm..."
# Using the nelm release install command
nelm release install -n default -r my-nelm-demo ./charts/mychart

echo "Deployment finished."
kubectl get all -l app=mychart
