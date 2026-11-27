############################
# Network (one public subnet, no NAT gateway = cheaper)
############################
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

############################
# Firewall (security group)
############################
resource "aws_security_group" "nodes" {
  name_prefix = "${var.project}-nodes-"
  description = "RKE2 cluster nodes"
  vpc_id      = aws_vpc.this.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project}-nodes"
  }
}

locals {
  # Ports that only YOUR IP may reach from the internet
  admin_ports = {
    ssh      = 22
    kube_api = 6443
    http     = 80
    https    = 443
  }
}

resource "aws_vpc_security_group_ingress_rule" "admin" {
  for_each = local.admin_ports

  security_group_id = aws_security_group.nodes.id
  description       = "${each.key} from allowed_cidr"
  cidr_ipv4         = var.allowed_cidr
  from_port         = each.value
  to_port           = each.value
  ip_protocol       = "tcp"
}

# Nodes may talk to each other on every port (needed by RKE2 and the pod network)
resource "aws_vpc_security_group_ingress_rule" "self" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "All traffic between cluster nodes"
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.nodes.id
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

############################
# SSH key, join token, OS image
############################
resource "aws_key_pair" "this" {
  key_name   = "${var.project}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# Shared secret that lets workers join the master
resource "random_password" "rke2_token" {
  length  = 40
  special = false
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (publisher of Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# Master (RKE2 server)
############################
resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.master_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.nodes.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data_server.sh.tftpl", {
    token        = random_password.rke2_token.result
    rke2_version = var.rke2_version
    node_name    = "${var.project}-master"
  })
  user_data_replace_on_change = true

  # IMDSv2 only (safer way for the instance to read its own metadata)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project}-master"
    Role = "master"
  }
}

############################
# Workers (RKE2 agents)
############################
resource "aws_instance" "worker" {
  count = var.worker_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.nodes.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data_agent.sh.tftpl", {
    token        = random_password.rke2_token.result
    rke2_version = var.rke2_version
    node_name    = "${var.project}-worker-${count.index + 1}"
    server_ip    = aws_instance.master.private_ip
  })
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project}-worker-${count.index + 1}"
    Role = "worker"
  }
}
