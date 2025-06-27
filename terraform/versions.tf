terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket = "srhoton-tfstate"
    key    = "steverhoton-bff/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}