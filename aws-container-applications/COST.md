# Cost & AWS Free Tier guide

> Prices are **us-east-1, on-demand list prices, approximate**, for ~730 hrs/month. They
> exclude tax, ALB LCU charges, and data transfer beyond the always-free 100 GB/mo. Always
> confirm with the [AWS Pricing Calculator](https://calculator.aws) for your region.

## TL;DR

**None of the three stacks are entirely Free Tier.** The blockers are the compute choices,
which have no free-tier coverage:

- `t3.small` nodes (ECS & EKS) — Free Tier only covers `t2.micro`/`t3.micro`.
- **Fargate** — no Free Tier at all.
- **EKS control plane** — a flat **$0.10/hr (~$73/mo)**, never free.

**But that's fine for how you're using these.** Running one stack at a time, validating,
then `terraform destroy` means you pay the *hourly* rate for only a couple of hours per
stack. A typical learning session costs **cents**, not the monthly figures below.

## Per-stack estimate (running 24×7)

| Resource | ECS (EC2) | Fargate | EKS |
|---|---|---|---|
| Compute | 2× t3.small ≈ $30 | 2 tasks (0.5 + 0.25 vCPU) ≈ $27 | 2× t3.small ≈ $30 |
| EKS control plane | — | — | $73 |
| ALB | ~$16 | ~$16 | ~$16 |
| RDS `db.t3.micro` + 20 GB | ~$15 | ~$15 | ~$15 |
| EBS node disks | ~$5 (2× 30 GB) | included | ~$3 (2× 20 GB) |
| Misc (ECR / logs / KMS) | ~$1 | ~$1 | ~$2 |
| **≈ Total / month** | **≈ $67** | **≈ $59** | **≈ $139** |
| **≈ Total / hour** | **≈ $0.09** | **≈ $0.08** | **≈ $0.19** |

## Your usage pattern: one at a time + 12-month Free Tier

Because the new-account 12-month Free Tier gives **one** RDS `db.t3.micro` (750 hrs) and
**one** ALB (750 hrs) per month, and you only ever run **one stack at a time**, those two
line items (~$31 combined) are effectively covered while a single stack is up. That leaves
only the compute:

| Stack (one running, Free Tier applied) | ≈ Net / month | ≈ Net / hour | A ~3 hr session |
|---|---|---|---|
| ECS (EC2) | ~$36 | ~$0.05 | **~$0.15** |
| Fargate | ~$28 | ~$0.04 | **~$0.12** |
| EKS | ~$108 | ~$0.14 | **~$0.42** (mostly the control plane) |

So a full learning pass — spin up ECS, then Fargate, then EKS, validating and destroying
each — totals **roughly $1**, as long as you destroy promptly. The 100 GB/mo of outbound
data transfer is always free and easily covers demo traffic.

> The risk is **forgetting to destroy**. The EKS control plane alone is ~$73/mo whether or
> not you use it. Treat `terraform destroy` as part of finishing each stack.

## What is / isn't Free Tier

| ✅ Free Tier eligible | ❌ Not Free Tier |
|---|---|
| RDS `db.t3.micro`, 750 hrs/mo + 20 GB (12 mo) | `t3.small` EC2 / EKS nodes |
| One ALB, 750 hrs/mo + 15 LCU (12 mo) | AWS Fargate (no free tier) |
| ECR private storage, 500 MB (12 mo) | EKS control plane ($0.10/hr) |
| EC2 `t2.micro` / `t3.micro`, 750 hrs/mo (12 mo) | A 2nd/3rd concurrent ALB or RDS |
| Data transfer out, 100 GB/mo (always free) | NAT Gateway — *avoided here by design* |

## Cost-reduction levers

- **ECS (EC2) → near-zero on a new account:** in `infra/ecs/terraform.tfvars` set
  `instance_type = "t3.micro"` and `desired_capacity = 1`. `t3.micro` is Free-Tier-eligible
  and already permitted by the variable validation. (Two containers on one `t3.micro` is
  tight on memory — fine for a light demo.) With Free-Tier RDS + ALB, this run approaches
  $0/mo.
- **Fargate:** no Free Tier, but it bills per second — the cheapest option for short,
  bursty sessions since idle time isn't charged once destroyed.
- **EKS:** the control-plane cost is fixed and cannot be reduced while the cluster exists,
  so the only real lever is **destroying promptly**. The node group can't drop below
  `t3.small` (variable validation), so EKS is inherently the priciest target.
- **Before destroying EKS:** run `kubectl delete ingress usermgmt` first so the AWS Load
  Balancer Controller removes its ALB, then `terraform destroy` (see
  [`infra/eks/README.md`](infra/eks/README.md)).
- **No NAT Gateway anywhere:** the stacks deliberately use public subnets, saving ~$32/mo
  per stack versus a private-subnet + NAT topology. (Demo-grade — not a production network.)

## Cleanup checklist

```bash
# from the stack folder you applied (infra/ecs, infra/fargate, or infra/eks)
kubectl delete ingress usermgmt   # EKS only — lets the controller delete its ALB first
terraform destroy
```
