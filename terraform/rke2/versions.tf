terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region

  # Every resource gets these tags (useful for finding costs later)
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}
