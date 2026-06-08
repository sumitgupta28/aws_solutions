# aws-jenkins-setup

Terraform module that provisions a single **Jenkins** server on AWS, designed to stay
within the **AWS Free Tier**.

## What it creates

| Resource | Free Tier note |
|---|---|
| EC2 instance (`t2.micro`/`t3.micro`, Amazon Linux 2023) | 750 hrs/month free for 12 months |
| Root EBS volume (`gp2`, 10 GiB default) | Up to 30 GiB gp2 free |
| Security group (SSH 22, Jenkins UI 8080) | Free |
| Auto-generated SSH key pair (saved locally) | Free |

It deploys into your account's **default VPC/subnet** and bootstraps Jenkins via
`user_data` (installs Java 17 + Jenkins LTS, enables and starts the service). The
bootstrap also installs **git** and the **Terraform CLI** (latest stable, from
HashiCorp's official repo) so Jenkins jobs can pull source and run `terraform`
directly on the host.

> Note: Free Tier covers compute and storage for new accounts. A small amount of
> outbound data transfer and public IPv4 address cost may still apply depending on
> your account age and AWS pricing changes. Always run `destroy` when finished.

## Prerequisites

- Terraform >= 1.3
- AWS credentials configured (`aws configure`, env vars, or an SSO profile)
- A default VPC in the chosen region (present by default on most accounts)

## Usage

```bash
# Optional: customize
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan
terraform apply
```

After apply completes, Terraform prints the Jenkins URL, SSH command, and how to
retrieve the initial admin password:

```bash
# SSH in (key is written to ./jenkins-key.pem)
ssh -i ./jenkins-key.pem ec2-user@<public-ip>

# Get the initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Then open `http://<public-ip>:8080` in your browser and complete setup.

> Jenkins takes ~2–4 minutes to finish installing after the instance boots.
> If the UI isn't up yet, wait a moment and retry.

## Access control

By default, SSH and the Jenkins UI are locked to **your current public IP** (auto-detected
via `checkip.amazonaws.com`). To set it explicitly, pass `allowed_cidr`:

```hcl
allowed_cidr = "203.0.113.10/32"
```

To make the Jenkins endpoint reachable **from anywhere on the internet** (e.g. so a
changing local IP keeps working), open it to the world:

```hcl
allowed_cidr = "0.0.0.0/0"
```

> ⚠️ `0.0.0.0/0` exposes SSH **and** the Jenkins login to the entire internet.
> Use it only for a short-lived sandbox: complete Jenkins setup promptly, set an
> admin password, and run `terraform destroy` when finished.

## Inputs

| Name | Description | Default |
|---|---|---|
| `aws_region` | Region to deploy into | `us-east-1` |
| `project_name` | Name prefix for resources | `jenkins` |
| `instance_type` | `t2.micro` or `t3.micro` | `t2.micro` |
| `root_volume_size` | Root volume GiB (<= 30) | `10` |
| `allowed_cidr` | CIDR allowed for SSH/UI (null = your IP) | `null` |
| `tags` | Extra tags for all resources | `{}` |

## Outputs

| Name | Description |
|---|---|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public IP |
| `jenkins_url` | Jenkins web UI URL |
| `ssh_command` | Ready-to-run SSH command |
| `initial_admin_password_command` | Command to fetch the admin password |

## Tear down

```bash
terraform destroy
```

This removes the instance, security group, key pair, and the locally generated key file.
