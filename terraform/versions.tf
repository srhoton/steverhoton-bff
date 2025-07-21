terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket = "steve-rhoton-tfstate"
    key    = "sr-bff/terraform.tfstate"
    region = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
