#!/bin/bash

set -e

GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

info() { echo "${YELLOW}🔄 $1...${RESET}"; }
success() { echo "${GREEN}✅ $1${RESET}"; }
error() { echo "${RED}❌ $1${RESET}"; }

echo "${BLUE}🚀 Starting Server Setup Script...${RESET}"
echo ""

info "Updating system packages"
sudo apt update && sudo apt upgrade -y
success "System updated"

info "Installing required dependencies"
sudo apt install -y ca-certificates curl gnupg lsb-release
success "Dependencies installed"

info "Adding Docker repository"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
success "Docker repository added"

info "Installing Docker"
sudo apt install -y docker-ce docker-ce-cli containerd.io
success "Docker installed"

info "Starting Docker service"
sudo systemctl enable docker
sudo systemctl start docker
success "Docker service started"

info "Adding user to Docker group"
sudo usermod -aG docker $USER
success "User added to Docker group"

info "Installing Docker Compose"
sudo apt install -y docker-compose-plugin
success "Docker Compose installed"

info "Adding Kubernetes repository"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
success "Kubernetes repository added"

info "Installing Kubernetes components"
sudo apt install -y kubeadm kubelet kubectl
success "Kubernetes components installed"

info "Holding Kubernetes versions"
sudo apt-mark hold kubeadm kubelet kubectl
success "Kubernetes components held"

info "Starting kubelet service"
sudo systemctl enable kubelet
sudo systemctl start kubelet
success "Kubelet service started"

info "Configuring log rotation for Docker"
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "7"
  }
}
EOF
sudo systemctl restart docker
success "Log rotation configured for Docker"

info "Configuring log rotation for Kubernetes logs"
cat <<EOF | sudo tee /etc/logrotate.d/kube-logs
/var/log/kube-apiserver.log
/var/log/kube-scheduler.log
/var/log/kube-controller-manager.log
/var/log/kubelet.log
/var/log/kube-proxy.log
{
  rotate 7
  daily
  compress
  missingok
  notifempty
  copytruncate
}
EOF
success "Log rotation configured for Kubernetes"

echo ""
echo "${GREEN}🎉 Installation complete!${RESET}"
echo ""

echo "${BLUE}🚀 Next Steps:${RESET}"
echo "-------------------------------------------"
echo "${YELLOW}🔹 1. Log out and log back in${RESET} to apply Docker group changes."
echo "   Run: ${GREEN}exit${RESET} and then reconnect to the server."
echo ""
echo "${YELLOW}🔹 2. Verify installations:${RESET}"
echo "   Run: ${GREEN}docker --version${RESET}  (Check Docker installation)"
echo "   Run: ${GREEN}docker compose version${RESET}  (Check Docker Compose)"
echo "   Run: ${GREEN}kubeadm version${RESET}  (Check Kubernetes installation)"
echo "   Run: ${GREEN}kubectl version --client${RESET}  (Check kubectl CLI)"
echo ""
echo "${YELLOW}🔹 3. Initialize Kubernetes (for master node only):${RESET}"
echo "   Run: ${GREEN}sudo kubeadm init --pod-network-cidr=192.168.0.0/16${RESET}"
echo ""
echo "   After initializing, set up kubectl for the current user:"
echo "   Run: ${GREEN}mkdir -p \$HOME/.kube${RESET}"
echo "   Run: ${GREEN}sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config${RESET}"
echo "   Run: ${GREEN}sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config${RESET}"
echo ""
echo "${YELLOW}🔹 4. Apply a networking plugin (example: Calico):${RESET}"
echo "   Run: ${GREEN}kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml${RESET}"
echo ""
echo "${YELLOW}🔹 5. Join worker nodes to the cluster (from worker node):${RESET}"
echo "   On worker nodes, run the join command output by 'kubeadm init'."
echo "   If lost, generate a new one on the master node:"
echo "   Run: ${GREEN}kubeadm token create --print-join-command${RESET}"
echo ""
echo "${YELLOW}🔹 6. Test Kubernetes:${RESET}"
echo "   Run: ${GREEN}kubectl get nodes${RESET} (Check if master is ready)"
echo "   Run: ${GREEN}kubectl run nginx --image=nginx --restart=Never${RESET} (Deploy a test pod)"
echo "   Run: ${GREEN}kubectl get pods${RESET} (Check if pod is running)"
echo ""
echo "-------------------------------------------"
echo "${GREEN}🎯 Your server is now ready for Kubernetes and Docker!${RESET}"
echo ""

