# Copy this file to terraform.tfvars and edit it. terraform.tfvars is ignored by Git.
project_id          = "your-gcp-project-id" # find it with: gcloud projects list
allowed_cidr        = "203.0.113.10/32"     # your public IP + /32  (find it with: curl.exe -s https://checkip.amazonaws.com)
region              = "asia-southeast1"
zone                = "asia-southeast1-b"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
# master_machine_type = "e2-medium"
# worker_machine_type = "e2-medium"
# worker_count        = 2
