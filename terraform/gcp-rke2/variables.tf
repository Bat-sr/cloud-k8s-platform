variable "project_id" {
  description = "Your Google Cloud PROJECT ID (not the display name). Find it with: gcloud projects list"
  type        = string
}

variable "project" {
  description = "Name prefix for all resources (lowercase letters, digits, hyphens)"
  type        = string
  default     = "rke2-lab"
}

variable "region" {
  description = "Google Cloud region. asia-southeast1 = Singapore (safe choice). asia-southeast3 = Bangkok (check that e2-medium exists there first)."
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "Zone inside the region (all nodes go in the same zone)"
  type        = string
  default     = "asia-southeast1-b"
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

variable "ssh_user" {
  description = "Linux user name that your SSH key is installed for"
  type        = string
  default     = "ubuntu"
}

variable "master_machine_type" {
  description = "Machine type for the master (RKE2 server needs about 4 GB RAM; e2-medium = 2 vCPU, 4 GB)"
  type        = string
  default     = "e2-medium"
}

variable "worker_machine_type" {
  description = "Machine type for the workers"
  type        = string
  default     = "e2-medium"
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

variable "disk_size_gb" {
  description = "Boot disk size per machine in GB"
  type        = number
  default     = 30
}

variable "rke2_version" {
  description = "Pin an RKE2 version such as v1.30.5+rke2r1. Leave empty to use the latest 'stable' release."
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "IP range of the new private subnet"
  type        = string
  default     = "10.20.1.0/24"
}
