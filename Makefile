IMAGE      ?= flash-cards-js
TAG        ?= latest
K3S_NODE   ?= k3s-node
K3S_ZONE   ?= us-east1-b
HELM_RELEASE := flash-cards-js
HELM_CHART   := ./helm/flash-cards-js
VALUES_GCP   := $(HELM_CHART)/values-gcp.yaml

.PHONY: help tf-init tf-import tf-plan build load deploy test all clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-12s %s\n", $$1, $$2}'

# --- Terraform ---
tf-init: ## Initialize Terraform
	cd terraform/gcp && terraform init

tf-import: tf-init ## Import existing GCP state
	cd terraform/gcp && chmod +x import-state.sh && ./import-state.sh

tf-plan: ## Run Terraform plan
	cd terraform/gcp && terraform plan

infra: tf-import tf-plan ## Import state + verify (no changes expected)

# --- Docker ---
build: ## Build Docker image (linux/amd64 for k3s)
	docker build --platform linux/amd64 -t $(IMAGE):$(TAG) .

load: build ## Build and load image into k3s node
	docker save $(IMAGE):$(TAG) | gcloud compute ssh $(K3S_NODE) --zone=$(K3S_ZONE) --command="sudo k3s ctr images import -"

# --- Helm ---
deploy: ## Deploy to k3s with Helm
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		-f $(VALUES_GCP) \
		--set image.repository=$(IMAGE) \
		--set image.tag=$(TAG)

# --- Test ---
test: ## Smoke test the live deployment
	@echo "Testing HTTPS..."
	@curl -sf https://flash.YOUR_IP.nip.io/healthz | grep -q ok && echo "  ✅ /healthz"
	@curl -sf https://flash.YOUR_IP.nip.io/api/decks | grep -q eks && echo "  ✅ /api/decks"
	@curl -sI http://flash.YOUR_IP.nip.io/ 2>&1 | grep -q 308 && echo "  ✅ HTTP→HTTPS redirect"

# --- Combos ---
all: infra build load deploy ## Full pipeline: infra, build, load, deploy

clean: ## Remove local Docker image
	docker rmi $(IMAGE):$(TAG) 2>/dev/null || true
