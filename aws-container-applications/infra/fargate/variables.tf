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
  default     = "usermgmt-fargate"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
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

variable "image_tag" {
  description = "Container image tag pulled from ECR for both services."
  type        = string
  default     = "latest"
}

variable "backend_cpu" {
  description = "Fargate CPU units for the backend task."
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Fargate memory (MiB) for the backend task."
  type        = number
  default     = 1024
}

variable "frontend_cpu" {
  description = "Fargate CPU units for the frontend task."
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Fargate memory (MiB) for the frontend task."
  type        = number
  default     = 512
}

variable "allowed_cidr" {
  description = "CIDR block allowed to reach the application load balancer on port 80."
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
