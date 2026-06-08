output "instance_id" {
  description = "EC2 instance ID of the Jenkins server."
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Public IP address of the Jenkins server."
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "URL for the Jenkins web UI."
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "ssh_command" {
  description = "Command to SSH into the Jenkins server."
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ec2-user@${aws_instance.jenkins.public_ip}"
}

output "initial_admin_password_command" {
  description = "Run this after SSHing in to retrieve the Jenkins initial admin password."
  value       = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}
