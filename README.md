**Deakin University | SIT722 — Software Deployment and Operations**

A fully automated CI/CD pipeline implementing test, staging, and production 
environments for a microservices application deployed on Azure Kubernetes Service.

The application consists of three backend microservices (product, order, customer)
and a frontend, containerised with Docker and orchestrated with Kubernetes.

---

## Pipeline Overview
Push to testing branch
│
▼
┌─────────────────────┐
│ CI — Run Tests │ ← pytest across all 3 microservices
│ (ci.yml) │ ← blocks builds if any test fails
└─────────┬───────────┘
│ pass
▼
┌─────────────────────┐
│ Build & Push Images│ ← Docker → Azure Container Registry
│ (build_and_push) │ ← tagged with commit SHA + testing-latest
└─────────┬───────────┘
│
▼
┌─────────────────────┐
│ Deploy to Staging │ ← OpenTofu provisions ephemeral AKS cluster
│ (cd-staging.yml) │ ← deploys to staging namespace
│ │ ← runs acceptance tests (health checks + retry)
│ │ ← tears down infrastructure on success
└─────────────────────┘

Push to main branch
│
▼
┌─────────────────────┐
│ Deploy to Prod │ ← deploys to permanent AKS prod namespace
│ (cd-prod.yml) │ ← verifies rollout (180s timeout per service)
└─────────────────────┘

---
## My Contributions
> The application code (FastAPI microservices, frontend) and pytest test suites
> were provided as part of the course material. My work covered the full
> DevOps layer:
- **GitHub Actions CI/CD pipelines** — all 4 workflow files
- **Docker containerisation** — Dockerfiles for all services
- **Kubernetes manifests** — deployments, services, configmaps, secrets, namespaces
- **Infrastructure as Code** — OpenTofu configuration for ephemeral staging on Azure
- **Acceptance testing** in the staging pipeline (health check validation with retry logic)
---
## Tech Stack
| Layer | Technology |
|---|---|
| CI/CD | GitHub Actions |
| Containerisation | Docker |
| Container Registry | Azure Container Registry (ACR) |
| Orchestration | Kubernetes (AKS) |
| Infrastructure as Code | OpenTofu (open-source Terraform) |
| Cloud | Microsoft Azure |
| Backend | Python / FastAPI |
| Database | PostgreSQL |
| Storage | Azure Blob Storage |
| Testing | pytest, httpx |
---
## Repository Structure
.github/
workflows/
ci.yml # Run tests, gate builds
build_and_push.yml # Build Docker images → ACR
cd-staging.yml # Provision staging, deploy, test, destroy
cd-prod.yml # Deploy to production AKS

backend/
product_service/ # FastAPI microservice + tests
order_service/ # FastAPI microservice + tests
customer_service/ # FastAPI microservice + tests

frontend/ # Frontend application

k8s/
namespace.yaml
configmap.yaml
product-service.yaml
order-service.yaml
customer-service.yaml
product-db.yaml
order-db.yaml
customer-db.yaml
frontend.yaml
secrets-staging.yaml
secrets-prod.yaml

infra/
staging/
main.tf # AKS cluster, storage, ACR role binding
variables.tf
outputs.tf
versions.tf

docker-compose.yml

---
## Pipeline Detail
### CI (`ci.yml`)
- Triggers on push to `testing` and `main` branches
- Runs `pytest` across all 3 backend microservices
- Uses `--maxfail=1` to stop on first failure
- Concurrency controls cancel stale in-progress runs on the same branch
- Docker image builds only proceed if all tests pass
### Build & Push (`build_and_push.yml`)
- Builds Docker images for all 4 services in parallel
- Pushes to Azure Container Registry with two tags:
  - `<commit-sha>` — for traceability
  - `testing-latest` / `prod-latest` — for environment targeting
### Staging CD (`cd-staging.yml`)
- Triggers automatically after CI passes on `testing` branch
- Provisions a fresh AKS cluster using OpenTofu (`tofu init → plan → apply`)
- Deploys all services to a `staging` Kubernetes namespace
- Waits for rollout completion (180s timeout per service)
- Runs acceptance tests: health checks on all 3 backend APIs + frontend HTML validation with retry logic (5 attempts, 5s interval)
- **Destroys the entire staging resource group** on success — zero idle cost
### Production CD (`cd-prod.yml`)
- Triggers after CI passes on `main` branch
- Deploys to a permanent AKS cluster in the `prod` namespace
- Injects live backend service IPs into the frontend at deploy time
- Verifies rollout status for all services before completing
---
## Infrastructure (OpenTofu)
Staging infrastructure is **fully ephemeral** — created per deployment, destroyed after acceptance tests pass.
Resources provisioned:
- Azure Resource Group
- AKS cluster (system-assigned managed identity)
- Azure Storage Account + private blob container
- ACR role assignment (AcrPull) for AKS → image pull
---
## Key Design Decisions
**Quality gate** — Tests are a hard prerequisite for builds. A failing test suite
stops the pipeline immediately; no broken image is ever pushed to the registry.
**Ephemeral staging** — Staging infrastructure is created fresh for every 
deployment and torn down after validation. This keeps costs near zero and 
ensures each staging run starts from a clean state.
**Dual image tagging** — Every image gets a commit SHA tag (immutable, 
traceable) and an environment tag (mutable, convenient for deployments).
**Environment isolation** — Staging and production run in separate Kubernetes
namespaces with separate secrets, preventing any cross-environment interference.
