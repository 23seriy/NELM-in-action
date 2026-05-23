#!/bin/bash
set -e

echo "Starting minikube cluster..."
minikube start --kubernetes-version=v1.28.3

echo "Cluster is ready."
kubectl get nodes
