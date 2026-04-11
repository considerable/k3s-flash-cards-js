#!/bin/bash
# Import existing GCP resources into Terraform state
# Run this once when setting up the project — resources already exist in GCP

set -euo pipefail

cd "$(dirname "$0")"

PROJECT="${TF_VAR_project_id:-$(gcloud config get-value project)}"
ZONE="${TF_VAR_zone:-us-east1-b}"

echo "🔧 Initializing Terraform..."
terraform init

echo "📋 Importing GCP resources into Terraform state..."

terraform import -var="project_id=$PROJECT" -var="zone=$ZONE" \
  google_compute_instance.k3s_node \
  "projects/$PROJECT/zones/$ZONE/instances/k3s-node" 2>/dev/null || echo "  ↳ k3s_node already in state"

terraform import -var="project_id=$PROJECT" -var="zone=$ZONE" \
  google_compute_firewall.allow_http_https \
  "projects/$PROJECT/global/firewalls/allow-http-https" 2>/dev/null || echo "  ↳ allow_http_https already in state"

terraform import -var="project_id=$PROJECT" -var="zone=$ZONE" \
  google_compute_firewall.allow_k3s_api \
  "projects/$PROJECT/global/firewalls/allow-k3s-api" 2>/dev/null || echo "  ↳ allow_k3s_api already in state"

terraform import -var="project_id=$PROJECT" -var="zone=$ZONE" \
  google_compute_firewall.allow_ssh \
  "projects/$PROJECT/global/firewalls/allow-ssh" 2>/dev/null || echo "  ↳ allow_ssh already in state"

terraform import -var="project_id=$PROJECT" -var="zone=$ZONE" \
  google_compute_firewall.allow_nodeports \
  "projects/$PROJECT/global/firewalls/allow-nodeports" 2>/dev/null || echo "  ↳ allow_nodeports already in state"

echo ""
echo "✅ Import complete. Verifying with plan..."
terraform plan

echo ""
echo "If plan shows no changes, the import was successful."
