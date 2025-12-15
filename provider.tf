terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"

  # 👇 Add this backend configuration. You must create the S3 bucket first.
  backend "s3" {
    bucket = "your-unique-terraform-state-bucket-name" # Create this bucket in AWS first
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}