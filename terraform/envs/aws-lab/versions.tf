terraform {
  required_version = ">= 1.10" # use_lockfile (S3 native locking) needs 1.10 or newer

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

  # Partial configuration: the bucket and region are not committed.
  # Pass them at init time:  terraform init -backend-config=backend.hcl
  backend "s3" {
    key          = "aws-lab/terraform.tfstate"
    encrypt      = true
    use_lockfile = true # lock file in the same bucket, no DynamoDB table needed
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
