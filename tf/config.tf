terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
  }

  backend "s3" {
    bucket = "ajromine-terraform-state"
    key    = "chess-engine/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}

data "aws_caller_identity" "current" {}