#!/bin/bash
set -e

echo "Uninstalling release with Nelm..."
nelm release uninstall -n default -r my-nelm-demo

echo "Cleaning up minikube cluster..."
minikube delete
