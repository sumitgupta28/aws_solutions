# Fargate stack — User Management on ECS (Fargate launch type)

Self-contained Terraform stack that runs the demo on **Amazon ECS with the Fargate
launch type** — serverless containers, no EC2 hosts to manage. It provisions its own
VPC, ECR repositories, RDS PostgreSQL, ECS cluster, two Fargate services, and an
Application Load Balancer with path-based routing (`/api/*` and `/actuator/*` → backend,
everything else → frontend).

> **Demo-grade networking:** tasks run in **public subnets with public IPs** and there is
> **no NAT Gateway** (saves ~$32/mo). RDS is not publicly accessible but lives in the same
> VPC. For production use private subnets + NAT.

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # set db_password, allowed_cidr
terraform init
terraform apply                                # creates network, ECR, RDS, ALB, cluster, services
```

The services will sit in a "pending/unhealthy" state until images exist in ECR. Build &
push both images (the commands are emitted as Terraform outputs):

```bash
# 1. Log Docker into ECR (see `terraform output docker_login_command`)
aws ecr get-login-password --region us-east-1 --profile infra-setup-user \
  | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

# 2. Build, tag, push (run from the repo root)
BACKEND=$(terraform output -raw ecr_backend_repository_url)
FRONTEND=$(terraform output -raw ecr_frontend_repository_url)
docker build -t "$BACKEND:latest"  ../../backend  && docker push "$BACKEND:latest"
docker build -t "$FRONTEND:latest" ../../frontend && docker push "$FRONTEND:latest"

# 3. Roll the services (see `terraform output force_new_deployment_command`)
```

Open `terraform output -raw app_url` and exercise the CRUD UI.

## Verify

- `aws ecs list-tasks --cluster <cluster>` shows running tasks.
- ALB target groups report **healthy** (EC2 → Target Groups in the console).
- The UI lists, creates, updates, and deletes users; data persists in RDS.

## Cost & cleanup

ALB ~$16–18/mo, RDS `db.t3.micro` Free-Tier-eligible (else ~$13/mo), Fargate billed per
vCPU/GB-second. **Always destroy when done:**

```bash
terraform destroy
```

## Key inputs

| Variable | Default | Notes |
|---|---|---|
| `aws_region` | `us-east-1` | |
| `aws_profile` | `infra-setup-user` | Named AWS CLI profile |
| `db_password` | _(required)_ | RDS master password |
| `allowed_cidr` | `0.0.0.0/0` | Restrict to your IP for a private demo |
| `image_tag` | `latest` | Tag pulled from ECR |

## Key outputs

`app_url`, `alb_dns_name`, `ecr_backend_repository_url`, `ecr_frontend_repository_url`,
`rds_endpoint`, `ecs_cluster_name`, plus `docker_login_command` and
`force_new_deployment_command` helpers.
