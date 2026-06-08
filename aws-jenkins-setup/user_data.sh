#!/bin/bash
set -euo pipefail

# Bootstrap a Jenkins server on Amazon Linux 2023.
# Logs are written to /var/log/cloud-init-output.log on the instance.

dnf update -y

# Jenkins requires Java (LTS supports Java 17). wget fetches the repo file;
# git lets Jenkins jobs pull source code.
dnf install -y java-17-amazon-corretto wget git

# Add the Jenkins package repository.
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

dnf install -y jenkins

# Start Jenkins now and on every boot.
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# --- Terraform ---------------------------------------------------------------
# Install the latest stable Terraform from HashiCorp's official repo so Jenkins
# jobs can run terraform on this host. dnf-plugins-core provides
# `dnf config-manager`, which isn't guaranteed on a fresh AL2023 image.
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
dnf install -y terraform
