#!/bin/bash

set -e  # Exit on error

##############################################
# Kubernetes & Docker Setup Script (Idempotent)
#
# This script installs and configures:
# - Docker and Containerd for Kubernetes
# - Kubernetes components (kubeadm, kubelet, kubectl)
# - Disables swap (required for K8s)
# - Configures log rotation for 7-day retention
# - Ensures everything is installed idempotently
# - Provides next steps after installation
#
# OS Compatibility: Debian 11+ / Ubuntu 22.04 LTS
##############################################

# Colors for better readability
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Update system and install dependencies
echo "${CYAN}🔄 Updating system packages...${RESET}"
sudo apt update -y && sudo apt upgrade -y

# Install required dependencies
echo "${CYAN}📦 Installing required dependencies...${RESET}"
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

# Disable Swap
echo "${CYAN}⚠️ Disabling swap...${RESET}"
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Install Docker if not installed
if ! command_exists docker; then
    echo "${GREEN}🐳 Installing Docker...${RESET}"
    sudo apt install -y docker-ce docker-ce-cli
    sudo systemctl enable --now docker
else
    echo "${YELLOW}✅ Docker is already installed.${RESET}"
fi

# Install Containerd if not installed
if ! command_exists containerd; then
    echo "${GREEN}📦 Installing Containerd...${RESET}"
    sudo apt install -y containerd.io
    sudo systemctl enable --now containerd
else
    echo "${YELLOW}✅ Containerd is already installed.${RESET}"
fi

# Configure Containerd only if needed
if ! grep -q "SystemdCgroup = true" /etc/containerd/config.toml 2>/dev/null; then
    echo "${CYAN}⚙️ Configuring Containerd...${RESET}"
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    sudo sed -i 's/^disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
    sudo systemctl restart containerd
else
    echo "${YELLOW}✅ Containerd is already configured.${RESET}"
fi

# Install Kubernetes Components if not installed
if ! command_exists kubectl; then
    echo "${GREEN}☸️ Installing Kubernetes components...${RESET}"
    if [ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]; then
        echo "${CYAN}🔑 Adding Kubernetes GPG key...${RESET}"
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    else
        echo "${YELLOW}✅ Kubernetes GPG key already exists.${RESET}"
    fi
    if ! grep -q "pkgs.k8s.io" /etc/apt/sources.list.d/kubernetes.list 2>/dev/null; then
        echo "${CYAN}📌 Adding Kubernetes repository...${RESET}"
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    else
        echo "${YELLOW}✅ Kubernetes repository already exists.${RESET}"
    fi
    sudo apt update -y
    sudo apt install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    sudo systemctl enable --now kubelet
else
    echo "${YELLOW}✅ Kubernetes components are already installed.${RESET}"
fi

# Set up log rotation if not already configured
LOGROTATE_CONFIG="/etc/logrotate.d/custom-logs"
if [ ! -f "$LOGROTATE_CONFIG" ]; then
    echo "${CYAN}⚙️ Setting up log rotation...${RESET}"
    sudo tee "$LOGROTATE_CONFIG" > /dev/null <<EOF
/var/log/docker/*.log
/var/log/kubernetes/*.log
/var/log/containerd/*.log
{
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root root
}
EOF
    sudo systemctl restart logrotate
else
    echo "${YELLOW}✅ Log rotation is already set up.${RESET}"
fi

# Post-Installation Steps
echo "${GREEN}🚀 Installation Complete! Next Steps:${RESET}"
echo "------------------------------------"
echo "🔹 Verify Docker:     ${CYAN}docker --version${RESET}"
echo "🔹 Verify Containerd: ${CYAN}containerd --version${RESET}"
echo "🔹 Verify KubeCtl:    ${CYAN}kubectl version --client${RESET}"
echo "🔹 Start Kubernetes:  ${CYAN}sudo kubeadm init${RESET}"
echo "🔹 Join a Node:       ${CYAN}sudo kubeadm token create --print-join-command${RESET}"
echo "🔹 Check Logs:        ${CYAN}sudo journalctl -u docker --since '1 hour ago'${RESET}"
echo "🔹 Disable Swap Check:${CYAN}swapon --summary  # Should return empty${RESET}"

