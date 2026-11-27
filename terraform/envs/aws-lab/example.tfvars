# Copy this file to terraform.tfvars and edit it. terraform.tfvars is ignored by Git.
allowed_cidr        = "203.0.113.10/32"   # your public IP + /32  (find it with: curl.exe -s https://checkip.amazonaws.com)
region              = "ap-southeast-1"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
# master_instance_type = "c7i-flex.large"
# worker_instance_type = "c7i-flex.large"
# worker_count         = 2
