#!/bin/bash
# Import Terraform state from k3s-gitlabci-golang-demo
# This avoids recreating existing GCP resources

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_STATE="$(cd "$SCRIPT_DIR/../../../k3s-gitlabci-golang-demo/terraform/gcp" && pwd)/terraform.tfstate"

if [ ! -f "$SOURCE_STATE" ]; then
  echo "❌ Source statefile not found: $SOURCE_STATE"
  echo "   Make sure k3s-gitlabci-golang-demo/terraform/gcp/terraform.tfstate exists"
  exit 1
fi

cd "$SCRIPT_DIR"

echo "🔧 Initializing Terraform..."
terraform init

echo "📋 Copying statefile from k3s-gitlabci-golang-demo..."
cp "$SOURCE_STATE" ./terraform.tfstate

echo "✅ State imported. Running plan to verify..."
terraform plan

echo ""
echo "If plan shows no changes, the import was successful."
echo "You can now manage this infrastructure from this project."
