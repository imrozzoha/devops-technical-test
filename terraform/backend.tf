terraform {
  backend "s3" {
    # Backend configuration is provided via backend-config.env
    # Initialize with: terraform init -backend-config=../backend-config.env
  }

  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
