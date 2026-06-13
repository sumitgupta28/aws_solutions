variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all resources."
  type        = string
  default     = "users-api"
}

variable "lambda_runtime" {
  description = "Lambda Python runtime. Must match the runtime the Pydantic layer was built for."
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_mb" {
  description = "Memory (MB) allocated to the Lambda function."
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "Lambda execution timeout in seconds."
  type        = number
  default     = 15
}

variable "log_level" {
  description = "Value for the function's LOG_LEVEL env var (DEBUG, INFO, WARNING, ERROR)."
  type        = string
  default     = "INFO"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the function's log group."
  type        = number
  default     = 14
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB users table. The application code hard-codes \"users\", so changing this requires a matching code change."
  type        = string
  default     = "users"
}

variable "layer_zip_path" {
  description = "Path to the pre-built Pydantic Lambda layer zip (built for Amazon Linux per DEPLOY.md, e.g. ../pydantic-layer.zip)."
  type        = string
}
