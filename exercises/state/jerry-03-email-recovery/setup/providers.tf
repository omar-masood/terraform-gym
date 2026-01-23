terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Exercise    = "jerry-03-email-recovery"
      Track       = "jerry"
      Category    = "state"
      ManagedBy   = "terraform"
      Environment = "training"
    }
  }
}
