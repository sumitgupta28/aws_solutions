variable "aws_region" {
  description = "AWS region to deploy the Jenkins server into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all created resources."
  type        = string
  default     = "jenkins"
}

variable "instance_type" {
  description = "EC2 instance type. t2.micro and t3.micro are AWS Free Tier eligible (750 hrs/month for 12 months)."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "To stay within the AWS Free Tier, use t2.micro or t3.micro."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB. Free Tier covers up to 30 GiB of gp2 storage."
  type        = number
  default     = 10

  validation {
    condition     = var.root_volume_size <= 30
    error_message = "Keep root_volume_size at 30 GiB or less to remain within the EBS Free Tier."
  }
}

variable "allowed_cidr" {
  description = "CIDR block allowed to reach SSH (22) and the Jenkins UI (8080). Leave null to auto-detect and restrict to your current public IP."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
