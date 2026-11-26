############################
# Network (custom VPC + one subnet; machines get public IPs, so no NAT needed)
############################
resource "google_compute_network" "this" {
  name                    = "${var.project}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = "${var.project}-subnet"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr
}

############################
# Firewall
############################
locals {
  node_tag = "${var.project}-node"
}

# Only YOUR IP may reach these ports from the internet
resource "google_compute_firewall" "admin" {
  name          = "${var.project}-allow-admin"
  network       = google_compute_network.this.name
  direction     = "INGRESS"
  source_ranges = [var.allowed_cidr]
  target_tags   = [local.node_tag]

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "80", "443"]
  }
}

# Nodes may talk to each other on every port (needed by RKE2 and the pod network)
resource "google_compute_firewall" "internal" {
  name          = "${var.project}-allow-internal"
  network       = google_compute_network.this.name
  direction     = "INGRESS"
  source_ranges = [var.subnet_cidr]
  target_tags   = [local.node_tag]

  allow {
    protocol = "all"
  }
}

# Shared secret that lets workers join the master
resource "random_password" "rke2_token" {
  length  = 40
  special = false
}

############################
# Master (RKE2 server)
############################
resource "google_compute_instance" "master" {
  name         = "${var.project}-master"
  machine_type = var.master_machine_type
  zone         = var.zone
  tags         = [local.node_tag]

  allow_stopping_for_update = true

  labels = {
    project    = var.project
    role       = "master"
    managed-by = "terraform"
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id

    # An empty block = give this machine a public IP
    access_config {}
  }

  metadata = {
    ssh-keys               = "${var.ssh_user}:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"
    block-project-ssh-keys = "true"
  }

  metadata_startup_script = templatefile("${path.module}/user_data_server.sh.tftpl", {
    token        = random_password.rke2_token.result
    rke2_version = var.rke2_version
    node_name    = "${var.project}-master"
  })
}

############################
# Workers (RKE2 agents)
############################
resource "google_compute_instance" "worker" {
  count = var.worker_count

  name         = "${var.project}-worker-${count.index + 1}"
  machine_type = var.worker_machine_type
  zone         = var.zone
  tags         = [local.node_tag]

  allow_stopping_for_update = true

  labels = {
    project    = var.project
    role       = "worker"
    managed-by = "terraform"
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id
    access_config {}
  }

  metadata = {
    ssh-keys               = "${var.ssh_user}:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"
    block-project-ssh-keys = "true"
  }

  metadata_startup_script = templatefile("${path.module}/user_data_agent.sh.tftpl", {
    token        = random_password.rke2_token.result
    rke2_version = var.rke2_version
    node_name    = "${var.project}-worker-${count.index + 1}"
    server_ip    = google_compute_instance.master.network_interface[0].network_ip
  })
}
