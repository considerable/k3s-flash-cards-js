# Copilot Instructions — k3s-flash-cards-js

## Project Overview
Express.js flash card app (server.js ~55 lines). Deployed on k3s running on a GCP VM.
Decks are JSON files in `decks/`. No database — files served directly.

## Stack
- Runtime: Node.js 22 (Alpine)
- Server: Express (~55 lines, server.js)
- Container: Docker (linux/amd64 — required for k3s on GCP x86 VM)
- Orchestration: k3s on GCP (single node, zone us-east1-b, VM name k3s-node)
- Helm chart: ./helm/flash-cards-js
- IaC: Terraform in ./terraform/gcp
- kubeconfig: ~/.kube/k3s-gcp.yaml

## Live URL
https://flash.YOUR_IP.nip.io

## Key Makefile Targets
| Target  | What it does |
|---------|-------------|
| `make build`  | Build linux/amd64 Docker image with cache bust |
| `make load`   | Build + SSH-pipe image into k3s node via gcloud |
| `make deploy` | Helm upgrade --install to k3s |
| `make all`    | Full pipeline: infra + build + load + deploy |
| `make test`   | Smoke test /healthz, /api/decks, HTTP→HTTPS redirect |
| `make clean`  | Remove local Docker image |

## Deploy Workflow (always in this order)
1. `make build`  — builds linux/amd64 image
2. `make load`   — pipes image into k3s node (no registry needed)
3. `make deploy` — Helm deploys to k3s
OR just: `make all`

## Adding a New Deck
1. Add JSON file to `decks/` following existing schema (name, sections[].cards[])
2. Run `make load deploy` — no code changes needed, decks are copied into image

## Important Constraints
- Image MUST be built `--platform linux/amd64` (k3s node is x86, not ARM)
- CACHE_BUST=$(date +%s) is required so k3s picks up new decks
- kubeconfig is exported in Makefile: `export KUBECONFIG := $(HOME)/.kube/k3s-gcp.yaml`
- Do NOT push to a registry — image is loaded directly via `gcloud compute ssh | k3s ctr images import`

## File Structure
```
server.js          # Express app (~55 lines)
Dockerfile         # node:22-alpine, copies decks/ at build time
Makefile           # all targets
helm/              # Helm chart for k3s deployment
terraform/gcp/     # GCP VM + firewall + static IP
decks/             # JSON flash card decks
public/            # Static HTML (deck.html)
```
