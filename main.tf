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
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Configure AWS S3 bucket
resource "aws_s3_bucket" "test_tfstate_bucket" {
  bucket = "riad-tfstate-bucket-2026"
}

resource "aws_dynamodb_table" "test_dynamo_table" {
  name = "scalingBackendTable"
  # Mode de facturation : ici gratuit :
  billing_mode = "PAY_PER_REQUEST"
  # for state locking use case
  hash_key = "LockID"
  # Locking state data type :
  attribute {
    name = "LockID"
    # type : chaine de caractères
    type = "S"
  }
}
