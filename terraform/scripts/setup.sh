#!/bin/bash

# --- SYSTEM CONFIGURATION ---

# 1. Disable Swap (Required by Kubernetes)
# Kubernetes scheduler will fail if swap is enabled.
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Load Kernel Modules
# 'overlay' and 'br_netfilter' are required for containerd networking.
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 3. Configure Sysctl Networking
# Allow IP forwarding and bridging.
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# --- INSTALLATION ---

# 4. Install Container Runtime (Containerd)
# Docker Engine is no longer the default for K8s, we use containerd directly.
apt-get update
apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io

# 5. Configure Containerd to use SystemdCgroup
# This is a critical step for kubelet stability.
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd

# 6. Install Kubernetes Tools (kubeadm, kubelet, kubectl)
# Determine the Kubernetes version (v1.29 is a stable choice for CKA).
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl

# Prevent automatic updates to avoid version mismatch during labs.
apt-mark hold kubelet kubeadm kubectl

echo "--- FRANKYS-KIT SETUP COMPLETED SUCCESSFULLY ---"