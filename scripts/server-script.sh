#!/bin/bash

set -e  # Exit on error

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

# ---------------------
# Install Docker
# ---------------------
if ! command_exists docker; then
    echo "${GREEN}🐳 Installing Docker...${RESET}"

    # Ensure Docker GPG key is added only if missing
    if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
        curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    else
        echo "${YELLOW}✅ Docker GPG key already exists, skipping...${RESET}"
    fi

    # Ensure repository is added only once
    if ! grep -q "download.docker.com" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    else
        echo "${YELLOW}✅ Docker repository already exists, skipping...${RESET}"
    fi

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable --now docker
else
    echo "${YELLOW}✅ Docker is already installed.${RESET}"
fi

# Install Docker Compose
if ! command_exists docker-compose; then
    echo "${GREEN}📦 Installing Docker Compose...${RESET}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "${YELLOW}✅ Docker Compose is already installed.${RESET}"
fi

# ---------------------
# Install Kubernetes Components
# ---------------------
if ! command_exists kubectl; then
    echo "${GREEN}☸️ Installing Kubernetes components...${RESET}"
    
    # Ensure Kubernetes GPG key is added only if missing
    if [ ! -f /usr/share/keyrings/kubernetes-archive-keyring.gpg ]; then
        curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    else
        echo "${YELLOW}✅ Kubernetes GPG key already exists, skipping...${RESET}"
    fi

    # Ensure repository is added only once
    if ! grep -q "apt.kubernetes.io" /etc/apt/sources.list.d/kubernetes.list 2>/dev/null; then
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    else
        echo "${YELLOW}✅ Kubernetes repository already exists, skipping...${RESET}"
    fi

    sudo apt update -y
    sudo apt install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
else
    echo "${YELLOW}✅ Kubernetes components are already installed.${RESET}"
fi

# ---------------------
# Setup Log Rotation
# ---------------------
echo "${CYAN}⚙️ Setting up log rotation for Docker & Kubernetes...${RESET}"

LOGROTATE_CONFIG="/etc/logrotate.d/custom-logs"

if [ ! -f "$LOGROTATE_CONFIG" ]; then
    sudo tee "$LOGROTATE_CONFIG" > /dev/null <<EOF
/var/log/docker/*.log
/var/log/kubernetes/*.log
{
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root root
}
EOF
    echo "${GREEN}✅ Log rotation configured.${RESET}"
else
    echo "${YELLOW}✅ Log rotation is already set up.${RESET}"
fi

# Restart logrotate to apply changes
sudo systemctl restart logrotate

# ---------------------
# Post-Installation Instructions
# ---------------------
echo "${GREEN}"
echo "🚀 Installation Complete! Next Steps:"
echo "------------------------------------"
echo "🔹 Verify Docker:     ${CYAN}docker --version${GREEN}"
echo "🔹 Verify KubeCtl:    ${CYAN}kubectl version --client${GREEN}"
echo "🔹 Start Kubernetes:  ${CYAN}sudo kubeadm init${GREEN}"
echo "🔹 Check Logs:        ${CYAN}sudo journalctl -u docker --since '1 hour ago'${GREEN}"
echo "🔹 Manage Logs:       ${CYAN}sudo logrotate -f /etc/logrotate.d/custom-logs${GREEN}"
echo "${RESET}"

