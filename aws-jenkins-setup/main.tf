locals {
  # Restrict access to the caller's public IP unless an explicit CIDR is given.
  allowed_cidr = var.allowed_cidr != null ? var.allowed_cidr : "${chomp(data.http.my_ip.response_body)}/32"

  common_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "terraform"
    },
    var.tags,
  )
}

# --- Lookups -----------------------------------------------------------------

# Auto-detect the caller's public IP for the default security group rule.
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Latest Amazon Linux 2023 AMI (free tier eligible with t2.micro/t3.micro).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Use the account's default VPC/subnet so apply and destroy stay simple.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- SSH key pair ------------------------------------------------------------

resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.jenkins.public_key_openssh
  tags       = local.common_tags
}

# Write the private key locally so you can SSH into the instance.
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.jenkins.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0400"
}

# --- Networking --------------------------------------------------------------

resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH and Jenkins UI access"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(local.common_tags, { Name = "${var.project_name}-sg" })

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  ingress {
    description = "Jenkins web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Compute -----------------------------------------------------------------

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  key_name                    = aws_key_pair.jenkins.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-server" })
}
