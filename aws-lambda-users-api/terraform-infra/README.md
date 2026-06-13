# terraform-infra

Terraform that provisions and deploys the **aws-lambda-users-api** serverless stack:

| Resource | Purpose |
| --- | --- |
| `aws_dynamodb_table.users` | `users` table, PK `userId` (String), on-demand billing, PITR on |
| `aws_lambda_function.users_api` | Python handler (`lambda_function.lambda_handler`) |
| `aws_lambda_layer_version.pydantic` | `pydantic` + `email-validator` layer (pre-built) |
| `aws_iam_role.lambda` (+ policies) | Least-privilege: DynamoDB CRUD on the table + CloudWatch Logs |
| `aws_apigatewayv2_*` | HTTP API with the 4 user routes, open (no auth) |
| `aws_cloudwatch_log_group.*` | Function + API access logs with retention |

The function zip is packaged by Terraform (`archive_file`) from `../lambda_function.py`
and `../models.py` — it rebuilds automatically when either file changes.

## Prerequisites

1. **AWS credentials** in the environment (`aws sts get-caller-identity` works).
2. **The Pydantic layer zip, built for Amazon Linux.** Terraform does *not* build
   it (it bundles compiled Rust that must match the Lambda runtime). Build it once
   per [`../DEPLOY.md`](../DEPLOY.md) step 1:

   ```bash
   cd ..
   mkdir -p layer/python
   docker run --rm --entrypoint /bin/sh \
     -v "$PWD":/var/task public.ecr.aws/lambda/python:3.12 \
     -c "pip install -r /var/task/requirements.txt -t /var/task/layer/python"
   (cd layer && zip -r ../pydantic-layer.zip python)
   ```

   This produces `../pydantic-layer.zip`. Rebuild it (and re-apply) whenever
   `requirements.txt` changes. Keep `lambda_runtime` here in sync with the
   `python:3.x` image you build against.

## Usage

```bash
cd terraform-infra
cp terraform.tfvars.example terraform.tfvars   # set layer_zip_path
terraform init
terraform plan
terraform apply
```

After apply, `terraform output api_base_url` gives the API base URL:

```bash
API=$(terraform output -raw api_base_url)

# Create
curl -sX POST "$API/users" -H 'Content-Type: application/json' \
  -d '{"name":"Ada Lovelace","email":"ada@example.com"}'

# Get / Update / Delete (use the userId returned above)
curl -s "$API/users/<userId>"
curl -sX PUT "$API/users/<userId>" -d '{"phone":"+1 555 123 4567"}'
curl -sX DELETE "$API/users/<userId>"
```

## Variables

| Variable | Default | Notes |
| --- | --- | --- |
| `layer_zip_path` | *(required)* | Path to the pre-built layer zip |
| `aws_region` | `us-east-1` | |
| `project_name` | `users-api` | Name prefix for all resources |
| `lambda_runtime` | `python3.12` | Must match the layer build image |
| `lambda_memory_mb` | `256` | |
| `lambda_timeout_seconds` | `15` | |
| `log_level` | `INFO` | Function `LOG_LEVEL` env var |
| `log_retention_days` | `14` | |
| `dynamodb_table_name` | `users` | Code hard-codes `users`; changing requires a code change |

## Notes

- **State is local** (`terraform.tfstate` in this dir). To go remote, add a
  `backend "s3"` block in `versions.tf` and `terraform init -migrate-state`.
- The table name `users` is hard-coded in `lambda_function.py` (`userTable`).
  If you change `dynamodb_table_name`, update the code to read it from an env
  var too, or the function will hit a non-existent table.
