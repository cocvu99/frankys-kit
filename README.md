# Franky's Kit 🏴‍☠️

**Franky's Kit** is an "Infrastructure as Code" solution to provision an ephemeral Kubernetes cluster on AWS. It uses **Terraform** to request cheap **Spot Instances** and automatically bootstraps the nodes with `containerd` and `kubeadm`.

Designed for **CKA (Certified Kubernetes Administrator)** preparation and DevOps experiments.

## Features

* **Cost-Effective:** Uses AWS Spot Instances (~$0.01/hour/node).
* **Fast Provisioning:** 1 Master + 2 Workers ready in < 3 minutes.
* **Exam-Ready:** Ubuntu 22.04 LTS, Containerd (SystemdCgroup), K8s v1.29.
* **Clean:** One command to destroy everything. No hidden costs.

## 🛠 Prerequisites

* **Terraform** (v1.0+)
* **AWS CLI** (Configured with `aws configure`)
* **SSH Key Pair** (Generated at `~/.ssh/frankys_key`)

## Quick Start

### 1. Provision Infrastructure
Clone the repo and navigate to the terraform directory:

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

Wait for the output. Terraform will display the SSH command and Public IPs.

### 2. Initialize Cluster (The "Hard" Way)
This kit installs the tools but lets you initialize the cluster manually for practice.

On Master Node:

```bash
# SSH into Master (use the command from Terraform output)
ssh -i ~/.ssh/frankys_key ubuntu@<MASTER_PUBLIC_IP>

# Initialize Control Plane
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Network Plugin (Flannel)
kubectl apply -f [https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml](https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml)
```

On Worker Nodes:
Copy the kubeadm join ... command output from the Master.

SSH into each worker and run the join command (with sudo).

### 3. Cleanup (Money Saver 💸)
When you finish your lab, destroy all resources immediately:

```bash
terraform destroy -auto-approve
```

Project Structure

Plaintext
frankys-kit/
├── terraform/
│   ├── main.tf          # Core infrastructure (VPC, Spot Instances)
│   ├── variables.tf     # Config (Instance type, Node count)
│   ├── outputs.tf       # SSH commands & IP outputs
│   └── scripts/
│       └── setup.sh     # Bootstrapping (Containerd, Kubeadm, Swapoff)
└── README.md


⚠️ Note
Data Persistence: This is an ephemeral lab. All data is lost upon terraform destroy.

Spot Instances: Instances may be reclaimed by AWS with a 2-minute warning (rare for short labs).