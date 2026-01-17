# --- NETWORK CONFIGURATION ---

# 1. VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "frankys-vpc"
  }
}

# 2. Internet Gateway (Required for internet access)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_vpc.id
}

# 3. Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Automatically assign Public IP
}

# 4. Route Table (Route traffic to Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- SECURITY ---

# 5. SSH Key Pair
# Uploads your local public key to AWS to allow SSH access.
resource "aws_key_pair" "frankys_auth" {
  key_name   = "frankys-key"
  public_key = file("~/.ssh/frankys_key.pub")
}

# 6. Security Group
resource "aws_security_group" "k8s_sg" {
  name   = "frankys-k8s-sg"
  vpc_id = aws_vpc.lab_vpc.id

  # Allow SSH from anywhere (For Lab purposes only)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow K8s API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all internal traffic between nodes (Important for CNI/Flannel/Calico)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Allow all outbound traffic (Install packages, pull images)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- COMPUTE INSTANCES (SPOT) ---

# 7. Master Node
resource "aws_spot_instance_request" "master" {
  ami           = "ami-0df7a207adb9748c7" # Ubuntu 22.04 LTS (ap-southeast-1)
  instance_type = var.instance_type
  spot_price    = var.spot_price
  spot_type     = "one-time"
  wait_for_fulfillment = true

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = aws_key_pair.frankys_auth.key_name

  # Bootstrapping script
  user_data = file("${path.module}/scripts/setup.sh")

  tags = {
    Name = "k8s-master"
    Role = "control-plane"
  }
}

# 8. Worker Nodes
resource "aws_spot_instance_request" "workers" {
  count         = var.worker_count
  ami           = "ami-0df7a207adb9748c7"
  instance_type = var.instance_type
  spot_price    = var.spot_price
  spot_type     = "one-time"
  wait_for_fulfillment = true

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = aws_key_pair.frankys_auth.key_name

  # Bootstrapping script
  user_data = file("${path.module}/scripts/setup.sh")

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}