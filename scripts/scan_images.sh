#!/usr/bin/env bash
set -euo pipefail
if ! command -v trivy >/dev/null 2>&1; then
  echo "Installing trivy..."
  sudo apt-get update && sudo apt-get install -y wget apt-transport-https gnupg lsb-release
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
  echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/trivy.list
  sudo apt-get update && sudo apt-get install -y trivy
fi
# Scan last pushed images from this run is non-trivial; this is a placeholder to scan workspace if needed.
echo "Trivy available. Ensure image scan in build step if required."
