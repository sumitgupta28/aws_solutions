# EKS stack — User Management on Amazon EKS

Self-contained Terraform stack that runs the demo on **Amazon EKS** with a managed EC2
node group. It provisions its own VPC, ECR repositories, RDS PostgreSQL, the EKS cluster
(via the `terraform-aws-modules/eks` module), an IRSA role + the **AWS Load Balancer
Controller** (Helm), and the Kubernetes workloads: `Deployment` + `Service` for backend
and frontend, a `Secret` for DB credentials, and an `Ingress` that provisions an
internet-facing ALB (`/api` and `/actuator` → backend, `/` → frontend).

> **Demo-grade networking:** nodes run in **public subnets with public IPs** and there is
> **no NAT Gateway**. RDS is not publicly accessible but lives in the same VPC. For
> production use private subnets + NAT.

## Prerequisites

`kubectl`, `helm`, and the AWS CLI installed locally. The `kubernetes`/`helm` providers
authenticate using `aws eks get-token` with the configured `aws_profile`.

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # set db_password
terraform init
terraform apply
```

Terraform creates the cluster, installs the Load Balancer Controller, and applies the
workloads. Pods stay in `ImagePullBackOff` until the images exist in ECR — build & push:

```bash
aws ecr get-login-password --region us-east-1 --profile infra-setup-user \
  | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

BACKEND=$(terraform output -raw ecr_backend_repository_url)
FRONTEND=$(terraform output -raw ecr_frontend_repository_url)
docker build -t "$BACKEND:latest"  ../../backend  && docker push "$BACKEND:latest"
docker build -t "$FRONTEND:latest" ../../frontend && docker push "$FRONTEND:latest"

# Configure kubectl (see `terraform output update_kubeconfig_command`) and restart:
aws eks update-kubeconfig --name <cluster> --region us-east-1 --profile infra-setup-user
kubectl rollout restart deployment/backend deployment/frontend
```

The Ingress takes a minute or two to provision the ALB. Get the URL with:

```bash
kubectl get ingress usermgmt        # ADDRESS column is the ALB hostname
# or: terraform output app_url   (re-run `terraform apply`/`refresh` to populate)
```

## Verify

- `kubectl get nodes` → nodes `Ready`.
- `kubectl get pods` → backend/frontend pods `Running`.
- `kubectl get ingress usermgmt` → an ALB hostname appears in ADDRESS.
- Open the ALB hostname and exercise the CRUD UI; data persists in RDS.

## Cost & cleanup

The **EKS control plane runs ~$73/mo regardless of usage** — this is the priciest target.
Add ALB (~$16–18/mo), RDS `db.t3.micro` (Free-Tier-eligible, else ~$13/mo), and the node
group (t3.small × `desired_capacity`). **Destroy promptly when done:**

```bash
# Delete the Ingress first so the controller removes its ALB before teardown:
kubectl delete ingress usermgmt
terraform destroy
```

## Key inputs

| Variable | Default | Notes |
|---|---|---|
| `aws_region` | `us-east-1` | |
| `aws_profile` | `infra-setup-user` | Named AWS CLI profile |
| `cluster_version` | `1.30` | EKS Kubernetes version |
| `db_password` | _(required)_ | RDS master password |
| `instance_type` | `t3.small` | Node group instance type |
| `desired_capacity` | `2` | Node count |
| `image_tag` | `latest` | Tag pulled from ECR |

## Key outputs

`app_url`, `ecr_backend_repository_url`, `ecr_frontend_repository_url`, `rds_endpoint`,
`cluster_name`, plus `docker_login_command` and `update_kubeconfig_command` helpers.
