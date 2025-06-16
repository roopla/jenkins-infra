#!/bin/bash
apt-get update
apt-get install -y unzip curl openjdk-17-jdk

TERRAFORM_VERSION="1.12.2"
curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
unzip terraform.zip
mv terraform /usr/local/bin/
rm terraform.zip

echo "Terraform installed:"
terraform -version
