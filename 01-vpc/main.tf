terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Configure Remote Backend (with State Locking)
  backend "s3" {
    bucket = "riad-tfstate-bucket-2026"
    # chemin virtuel et nom sous lequel tfstate file sera stocké dans le bucket S3
    key    = "projet-dx/terraform.tfstate"
    region = "eu-west-3"
    # if S3 State Locking :
    # use_lockfile = true
    dynamodb_table = "scalingBackendTable"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-3"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}
