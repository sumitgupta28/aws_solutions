variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Named AWS CLI profile used for credentials (matches the sibling jenkins module)."
  type        = string
  default     = "infra-setup-user"
}

variable "project_name" {
  description = "Name prefix applied to all created resources."
  type        = string
  default     = "usermgmt-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "usermgmt"
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "usermgmt"
}

variable "db_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class. db.t3.micro is Free Tier eligible for new accounts."
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = contains(["db.t3.micro", "db.t4g.micro", "db.t3.small"], var.db_instance_class)
    error_message = "Use db.t3.micro (Free Tier eligible) or another small instance for this demo."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the EKS managed node group."
  type        = string
  default     = "t3.small"

  validation {
    condition     = contains(["t3.small", "t3.medium", "t3.large"], var.instance_type)
    error_message = "Use t3.small, t3.medium, or t3.large (t3.small recommended for the demo)."
  }
}

variable "desired_capacity" {
  description = "Number of nodes in the managed node group."
  type        = number
  default     = 2
}

variable "image_tag" {
  description = "Container image tag pulled from ECR for both workloads."
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
