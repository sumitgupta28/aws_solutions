terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Local state (terraform.tfstate in this directory). To move to a remote
  # backend later, add a `backend "s3" { ... }` block here and run `terraform init -migrate-state`.
}
