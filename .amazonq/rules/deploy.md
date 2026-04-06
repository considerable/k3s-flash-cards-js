# k3s-flash-cards-js — Amazon Q Developer Rules

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

## Deploy Workflow — ALWAYS in this order
1. `make build`  — builds linux/amd64 Docker image with cache bust
2. `make load`   — SSH-pipes image into k3s node (no registry needed)
3. `make deploy` — Helm upgrade --install to k3s

Or all at once: `make all`

## Key Makefile Targets
| Target        | What it does |
|---------------|-------------|
| `make build`  | Build linux/amd64 Docker image with cache bust |
| `make load`   | Build + SSH-pipe image into k3s node via gcloud |
| `make deploy` | Helm upgrade --install to k3s |
| `make all`    | Full pipeline: infra + build + load + deploy |
| `make test`   | Smoke test /healthz, /api/decks, HTTP→HTTPS redirect |
| `make clean`  | Remove local Docker image |

## Critical Constraints — Never Violate
- Image MUST be built `--platform linux/amd64` (k3s node is x86, not ARM)
- CACHE_BUST=$(date +%s) is required — without it k3s may serve stale deck content
- Do NOT suggest `docker push` or a registry — images load directly via SSH pipe
- kubeconfig is exported in Makefile: `export KUBECONFIG := $(HOME)/.kube/k3s-gcp.yaml`
- Single-node k3s — no need to load image on multiple nodes

## Adding a New Deck
1. Drop a JSON file in `decks/` following the schema below
2. Run `make load deploy` — no code changes needed
3. Deck appears automatically at `https://flash.YOUR_IP.nip.io/<slug>`

## Deck JSON Schema
```json
{
  "name": "Deck Name (YYYY-MM-DD)",
  "sections": [
    {
      "name": "Section Name",
      "cards": [
        {
          "num": 1,
          "front": "Question or term",
          "back": "Answer or definition",
          "link": "https://optional-reference-url.com"
        }
      ]
    }
  ]
}
```

## File Structure
```
server.js          # Express app (~55 lines)
Dockerfile         # node:22-alpine, copies decks/ at build time
Makefile           # all targets
helm/              # Helm chart for k3s deployment
terraform/gcp/     # GCP VM + firewall + static IP
decks/             # JSON flash card decks — drop files here
public/            # Static HTML (deck.html)
.amazonq/rules/    # Amazon Q Developer workspace rules (this file)
.github/           # GitHub Copilot instructions
.vscode/           # VS Code tasks
```
