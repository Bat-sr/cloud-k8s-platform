variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "rke2-lab"
}

variable "region" {
  description = "AWS region (Singapore is close to Thailand)"
  type        = string
  default     = "ap-southeast-1"
}

variable "allowed_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32. Checked by the module (0.0.0.0/0 is rejected)."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your SSH PUBLIC key file (the .pub file)"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "master_instance_type" {
  description = "Instance type for the master"
  type        = string
  default     = "c7i-flex.large"
}

variable "worker_instance_type" {
  description = "Instance type for the workers"
  type        = string
  default     = "c7i-flex.large"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}
