# aws-container-applications

A small **User Management** demo (no auth) used to showcase deploying the *same*
containerized app across the three main AWS container compute models: **ECS on EC2**,
**ECS on Fargate**, and **EKS**. A single page lets you create, list, update, and delete
users.

```
Browser ──> ALB / Ingress ──┬─> frontend (React + nginx, static)        :80
                            └─> backend  (Spring Boot + Java)    /api    :8080 ──> PostgreSQL (RDS)
```

## Components

| Path | What |
|---|---|
| `backend/` | Spring Boot 3.3 (Java 21, Gradle) REST API on `/api/users`, Flyway migrations, actuator health probes. |
| `frontend/` | React 18 + Vite SPA (plain JS), served by nginx. Calls a relative `/api`. |
| `docker-compose.yml` | Postgres + backend + frontend wired for local development. |
| `infra/ecs/` | Terraform: ECS on the **EC2** launch type. |
| `infra/fargate/` | Terraform: ECS on the **Fargate** launch type. |
| `infra/eks/` | Terraform: **EKS** + managed node group + AWS Load Balancer Controller. |

### One image, every target

The backend reads all DB settings from environment variables and the frontend calls a
relative `/api` path (routed by nginx locally, and by the ALB/Ingress in the cloud). So
the **same two images** run unchanged in docker-compose and all three cloud stacks — no
per-environment rebuilds.

## Run locally (start here — zero cost)

```bash
cp .env.example .env
docker compose up --build
```

- App: <http://localhost:3000>
- API health: <http://localhost:8080/actuator/health>
- API: `curl http://localhost:8080/api/users`

Data persists in the `pgdata` volume across restarts. Run backend tests with:

```bash
cd backend && ./gradlew test
```

## Deploy to AWS

Each `infra/<target>/` folder is a **fully standalone** Terraform stack (its own VPC, ECR,
RDS, cluster, and load balancer) so you can stand up / tear down one at a time. The
general flow, detailed in each folder's README:

1. `cp terraform.tfvars.example terraform.tfvars` and set `db_password` (and `allowed_cidr`).
2. `terraform init && terraform apply` — provisions network, ECR, RDS, cluster, ALB.
3. Build and push both images to the ECR repos (URIs are Terraform outputs).
4. Roll the services / restart deployments so they pull the images.
5. Open the `app_url` output and use the CRUD UI.
6. `terraform destroy` when finished.

| Target | Folder | Notes |
|---|---|---|
| ECS on EC2 | [`infra/ecs/`](infra/ecs/README.md) | You manage EC2 capacity (ASG). |
| ECS on Fargate | [`infra/fargate/`](infra/fargate/README.md) | Serverless tasks. |
| EKS | [`infra/eks/`](infra/eks/README.md) | Kubernetes + ALB Ingress. |

> ⚠️ **Cost warning.** These stacks create billable resources (ALB ~$16–18/mo, RDS, and —
> for EKS — a control plane at **~$73/mo regardless of usage**). The demo deliberately uses
> public subnets and **no NAT Gateway** to save cost; this is not a production network
> topology. **Always run `terraform destroy` when you are done.** See **[COST.md](COST.md)**
> for per-stack estimates and Free Tier guidance.

## Conventions

The Terraform stacks match the sibling `../aws-jenkins-setup` module: AWS provider `~> 5.0`,
a named `aws_profile` (default `infra-setup-user`), `us-east-1` default region, and
Free-Tier-conscious defaults.
