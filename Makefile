IMAGE        ?= flash-cards-js
TAG          := $(shell date +%s)
K3S_NODE     ?= k3s-node
K3S_ZONE     ?= us-east1-b
GCP_PROJECT  ?= $(shell gcloud config get-value project 2>/dev/null)
APP_HOST     ?= flash.$(shell gcloud compute addresses describe k3s-ip --region=us-east1 --format='value(address)' 2>/dev/null || echo localhost).nip.io
HELM_RELEASE := flash-cards-js
HELM_CHART   := ./helm/flash-cards-js
VALUES_GCP   := $(HELM_CHART)/values-gcp.yaml

export KUBECONFIG := $(HOME)/.kube/k3s-gcp.yaml

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
	@docker info >/dev/null 2>&1 || (echo "Starting Docker..." && open -a Docker && while ! docker info >/dev/null 2>&1; do sleep 2; done)
	docker build --platform linux/amd64 --build-arg CACHE_BUST=$(TAG) -t $(IMAGE):$(TAG) .

load: ## Build and load image into k3s node
	@docker info >/dev/null 2>&1 || (echo "Starting Docker..." && open -a Docker && while ! docker info >/dev/null 2>&1; do sleep 2; done)
	docker build --platform linux/amd64 --build-arg CACHE_BUST=$(TAG) -t $(IMAGE):$(TAG) .
	docker save $(IMAGE):$(TAG) | gcloud compute ssh $(K3S_NODE) --zone=$(K3S_ZONE) --command="sudo k3s ctr images import -"

# --- Helm ---
deploy: ## Deploy to k3s with Helm (tag change triggers automatic pod restart)
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		-f $(VALUES_GCP) \
		--set image.repository=$(IMAGE) \
		--set image.tag=$(TAG)
	@echo "Rollout started — check status with: kubectl get pods -l app=flash-cards-js"

# --- Test ---
test: ## Smoke test the live deployment
	@echo "Testing https://$(APP_HOST) ..."
	@curl -sf https://$(APP_HOST)/healthz | grep -q ok && echo "  ✅ /healthz"
	@curl -sf https://$(APP_HOST)/api/decks | grep -q terraform && echo "  ✅ /api/decks"
	@curl -sI http://$(APP_HOST)/ 2>&1 | grep -q 308 && echo "  ✅ HTTP→HTTPS redirect"
	@echo "" && read -p "Open in browser? [y/N] " ans && [ "$$ans" = "y" ] && open https://$(APP_HOST) || true

# --- Combos ---
all: infra build load deploy ## Full pipeline: infra, build, load, deploy

clean: ## Remove local Docker image
	docker rmi $(IMAGE):$(TAG) 2>/dev/null || true

prune: ## Keep 2 most recent images on k3s node, delete the rest
	gcloud compute ssh $(K3S_NODE) --zone=$(K3S_ZONE) --command="\
		sudo k3s ctr images ls -q | grep flash-cards-js | sort -t: -k2 -n | head -n -2 | \
		xargs -r sudo k3s ctr images rm"
