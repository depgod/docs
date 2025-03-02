---
  
These steps assume we are using Ubuntu 24.04 LTS for host os and vm images.
  
## Setup multipass
```bash
$ sudo snap install multipass
```

## Provision Virtual Machines Using Multipass
```bash
# Create master and worker nodes 
$ multipass launch --name master --cpus 2 --mem 4G --disk 20G 
$ multipass launch --name worker1 --cpus 2 --mem 4G --disk 20G 
$ multipass launch --name worker2 --cpus 2 --mem 4G --disk 20G 

# Get shell access to nodes 
$ multipass shell master 
$ multipass shell worker1 
$ multipass shell worker2 

# Get IP addresses of nodes 
$ multipass list
```
## Server preparation
Run these on all multipass vms

```bash
# Update system packages
$ sudo apt update && sudo apt upgrade -y

# Install required dependencies
$ sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker repository
$ sudo mkdir -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
$ sudo apt update
$ sudo apt install -y containerd.io

# Enable and start containerd
$ sudo systemctl enable containerd
$ sudo systemctl start containerd

# Generate default config
$ sudo mkdir -p /etc/containerd
$ containerd config default | sudo tee /etc/containerd/config.toml

# Modify config.toml
$ sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

$ sudo sed -i 's/^disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml

# Restart containerd
$ sudo systemctl restart containerd
```

## Configure vm systems settings for kubernetes

```bash
# Disable swap
$ sudo swapoff -a
$ sudo sed -i '/swap/d' /etc/fstab

# Load kernel modules
$ cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

$ sudo modprobe overlay
$ sudo modprobe br_netfilter

# Configure sysctl params
$ cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

$ sudo sysctl --system

```

## Install kubernetes componenets

```bash
# Add Kubernetes repository
$ curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

$ echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubeadm, kubelet, kubectl
$ sudo apt update
$ sudo apt install -y kubelet kubeadm kubectl

# Prevent accidental upgrades
$ sudo apt-mark hold kubelet kubeadm kubectl

# Enable and start kubelet
$ sudo systemctl enable kubelet
$ sudo systemctl start kubelet

```

## Initilize the kubernetes cluster (Master node only)

```bash
# Initialize cluster, if it runs successfully it will print a kubeadm join command which can be used to make worker nodes/vms to the cluster
$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Setup kubeconfig for non-root user
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Setup a container network interface (cni)

```bash
# Install Flannel CNI
$ kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

## Join all worker vms/nodes

```bash
# Retrieve join command from master node
$ kubeadm token create --print-join-command

# Run the outputted command on worker nodes
$ sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

```

## Verify kubernetes cluster

```bash
# Check node status
$ kubectl get nodes

# Verify all pods are running
$ kubectl get pods -A
```

