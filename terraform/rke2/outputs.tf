output "master_public_ip" {
  description = "Public IP of the master node"
  value       = aws_instance.master.public_ip
}

output "worker_public_ips" {
  description = "Public IPs of the worker nodes"
  value       = aws_instance.worker[*].public_ip
}

output "ssh_master" {
  description = "Command to log in to the master"
  value       = "ssh ubuntu@${aws_instance.master.public_ip}"
}

output "kubeconfig_hint" {
  description = "How to use kubectl from your laptop"
  value       = "ssh ubuntu@${aws_instance.master.public_ip} 'cat /etc/rancher/rke2/rke2.yaml' > rke2.yaml  (then replace 127.0.0.1 with ${aws_instance.master.public_ip} inside rke2.yaml)"
}

output "rke2_token" {
  description = "Cluster join token (secret)"
  value       = random_password.rke2_token.result
  sensitive   = true
}
