terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-3"
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
