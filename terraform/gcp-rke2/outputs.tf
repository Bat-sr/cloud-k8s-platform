output "master_public_ip" {
  description = "Public IP of the master node"
  value       = google_compute_instance.master.network_interface[0].access_config[0].nat_ip
}

output "worker_public_ips" {
  description = "Public IPs of the worker nodes"
  value       = [for w in google_compute_instance.worker : w.network_interface[0].access_config[0].nat_ip]
}

output "ssh_master" {
  description = "Command to log in to the master"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.master.network_interface[0].access_config[0].nat_ip}"
}

output "kubeconfig_hint" {
  description = "How to use kubectl from your laptop"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.master.network_interface[0].access_config[0].nat_ip} 'cat /etc/rancher/rke2/rke2.yaml' > rke2.yaml  (then replace 127.0.0.1 with ${google_compute_instance.master.network_interface[0].access_config[0].nat_ip} inside rke2.yaml)"
}

output "rke2_token" {
  description = "Cluster join token (secret)"
  value       = random_password.rke2_token.result
  sensitive   = true
}
