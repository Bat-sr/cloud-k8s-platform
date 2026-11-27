variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "rke2-lab"
}

variable "allowed_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32. Only this address can reach SSH, the Kubernetes API and ports 80/443."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_cidr, 0)) && var.allowed_cidr != "0.0.0.0/0"
    error_message = "Use a valid CIDR such as 203.0.113.10/32. 0.0.0.0/0 (open to the whole internet) is not allowed."
  }
}

variable "ssh_public_key_path" {
  description = "Path to your SSH PUBLIC key file (the .pub file)"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "master_instance_type" {
  description = "Instance type for the master (RKE2 server needs about 4 GB RAM)"
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

  validation {
    condition     = var.worker_count >= 1
    error_message = "worker_count must be at least 1."
  }
}

variable "root_volume_gb" {
  description = "Disk size per instance in GB"
  type        = number
  default     = 30
}

variable "rke2_version" {
  description = "Pin an RKE2 version such as v1.30.5+rke2r1. Leave empty to use the latest 'stable' release."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "IP range of the new private network"
  type        = string
  default     = "10.20.0.0/16"
}
