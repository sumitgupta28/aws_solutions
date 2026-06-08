# ECS stack — User Management on ECS (EC2 launch type)

Self-contained Terraform stack that runs the demo on **Amazon ECS with the EC2 launch
type** — you own the container-host capacity via an Auto Scaling group of EC2 instances
registered to the cluster. It provisions its own VPC, ECR repositories, RDS PostgreSQL,
ECS cluster, a Launch Template + ASG, two ECS services using **bridge networking with
dynamic host ports**, and an Application Load Balancer with path-based routing
(`/api/*` and `/actuator/*` → backend, everything else → frontend).

> **Demo-grade networking:** instances run in **public subnets with public IPs** and there
> is **no NAT Gateway**. RDS is not publicly accessible but lives in the same VPC. For
> production use private subnets + NAT.

## How capacity works here

The Launch Template uses the ECS-optimized Amazon Linux 2023 AMI (resolved from SSM) and
joins instances to the cluster via `ECS_CLUSTER` in `/etc/ecs/ecs.config`. The two ECS
services then schedule tasks onto whichever container instances have room. Because tasks
use bridge networking with `hostPort = 0`, the ALB target groups are `target_type =
"instance"` and the app security group allows the ephemeral port range (32768–65535) from
the ALB.

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # set db_password, allowed_cidr
terraform init
terraform apply
```

Then build & push both images (commands are emitted as Terraform outputs):

```bash
aws ecr get-login-password --region us-east-1 --profile infra-setup-user \
  | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

BACKEND=$(terraform output -raw ecr_backend_repository_url)
FRONTEND=$(terraform output -raw ecr_frontend_repository_url)
docker build -t "$BACKEND:latest"  ../../backend  && docker push "$BACKEND:latest"
docker build -t "$FRONTEND:latest" ../../frontend && docker push "$FRONTEND:latest"

# Roll the services (see `terraform output force_new_deployment_command`)
```

Open `terraform output -raw app_url` and exercise the CRUD UI.

## Verify

- `aws ecs list-container-instances --cluster <cluster>` shows the registered EC2 hosts.
- `aws ecs list-tasks --cluster <cluster>` shows running tasks; target groups go healthy.
- The UI lists/creates/updates/deletes users; data persists in RDS.

## Cost & cleanup

ALB ~$16–18/mo, RDS `db.t3.micro` Free-Tier-eligible (else ~$13/mo), plus the EC2
instances (t3.small × `desired_capacity`). **Always destroy when done:**

```bash
terraform destroy
```

## Key inputs

| Variable | Default | Notes |
|---|---|---|
| `aws_region` | `us-east-1` | |
| `aws_profile` | `infra-setup-user` | Named AWS CLI profile |
| `db_password` | _(required)_ | RDS master password |
| `instance_type` | `t3.small` | ECS container instance size |
| `desired_capacity` | `2` | EC2 instances in the ASG |
| `allowed_cidr` | `0.0.0.0/0` | Restrict to your IP for a private demo |
| `image_tag` | `latest` | Tag pulled from ECR |

## Key outputs

`app_url`, `alb_dns_name`, `ecr_backend_repository_url`, `ecr_frontend_repository_url`,
`rds_endpoint`, `ecs_cluster_name`, plus `docker_login_command` and
`force_new_deployment_command` helpers.
