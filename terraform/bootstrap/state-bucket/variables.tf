variable "region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "ap-southeast-1"
}

variable "bucket_name" {
  description = "Globally unique bucket name. Leave null to use rke2-lab-tfstate-<your AWS account id>."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_name == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Use 3-63 characters: lowercase letters, digits, dots and hyphens."
  }
}
