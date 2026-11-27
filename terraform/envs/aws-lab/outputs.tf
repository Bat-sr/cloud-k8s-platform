output "master_public_ip" {
  description = "Public IP of the master node"
  value       = module.cluster.master_public_ip
}

output "worker_public_ips" {
  description = "Public IPs of the worker nodes"
  value       = module.cluster.worker_public_ips
}

output "ssh_master" {
  description = "Command to log in to the master"
  value       = module.cluster.ssh_master
}

output "kubeconfig_hint" {
  description = "How to use kubectl from your laptop"
  value       = module.cluster.kubeconfig_hint
}

output "rke2_token" {
  description = "Cluster join token (secret)"
  value       = module.cluster.rke2_token
  sensitive   = true
}
