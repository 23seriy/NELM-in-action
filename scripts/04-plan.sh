#!/bin/bash
set -e

echo "Planning an update with Nelm (changing replica count)..."
# This showcases the terraform-like plan feature
nelm release plan install -n default -r my-nelm-demo ./charts/mychart --set replicaCount=3

echo ""
echo "If you want to apply this plan, run:"
echo "nelm release install -n default -r my-nelm-demo ./charts/mychart --set replicaCount=3"
