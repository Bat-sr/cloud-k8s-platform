module "cluster" {
  source = "../../modules/rke2-cluster"

  project              = var.project
  allowed_cidr         = var.allowed_cidr
  ssh_public_key_path  = var.ssh_public_key_path
  master_instance_type = var.master_instance_type
  worker_instance_type = var.worker_instance_type
  worker_count         = var.worker_count
}
