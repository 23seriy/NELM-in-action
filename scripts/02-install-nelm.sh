#!/bin/bash
set -e

echo "Installing Nelm..."
# Currently nelm is distributed as part of werf or standalone CLI. 
# We'll download the latest nelm binary for macOS or Linux.
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi
if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi

curl -sL "https://github.com/werf/nelm/releases/latest/download/nelm-${OS}-${ARCH}" -o nelm
chmod +x nelm
sudo mv nelm /usr/local/bin/nelm

echo "Nelm installed successfully."
nelm version || echo "Nelm version command executed"
