output "app_url" {
  description = "URL of the ALB created by the Ingress (populated a minute or two after apply)."
  value       = try("http://${kubernetes_ingress_v1.app.status[0].load_balancer[0].ingress[0].hostname}", "pending - run: kubectl get ingress usermgmt")
}

output "ecr_backend_repository_url" {
  description = "Push the backend image here."
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_repository_url" {
  description = "Push the frontend image here."
  value       = aws_ecr_repository.frontend.repository_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (reachable only from within the VPC)."
  value       = aws_db_instance.postgres.address
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "docker_login_command" {
  description = "Authenticate Docker to ECR before pushing."
  value       = "aws ecr get-login-password --region ${var.aws_region} --profile ${var.aws_profile} | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.backend.repository_url)[0]}"
}

output "update_kubeconfig_command" {
  description = "Configure kubectl for this cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region} --profile ${var.aws_profile}"
}
