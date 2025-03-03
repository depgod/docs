# Kubectl Command Cheat Sheet

This comprehensive cheat sheet provides a quick reference for commonly used kubectl commands, organized by category for easy access.

## Cluster Management

### Cluster Information
```bash
# View cluster information
kubectl cluster-info

# Check the health status of cluster components
kubectl get componentstatuses

# View nodes in the cluster
kubectl get nodes
kubectl get nodes -o wide  # Detailed view

# Get API versions available
kubectl api-versions
```

### Context and Configuration
```bash
# View kubeconfig settings
kubectl config view

# Show current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch to a different context
kubectl config use-context <context-name>
```

## Resource Management

### Pods
```bash
# List all pods
kubectl get pods
kubectl get pods -A  # across all namespaces
kubectl get pods -n <namespace>  # in specific namespace

# Get detailed pod information
kubectl describe pod <pod-name>

# Delete a pod
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> --force  # Force deletion

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/bash
```

### Deployments
```bash
# List deployments
kubectl get deployments

# Create deployment
kubectl create deployment <name> --image=<image>

# Scale deployment
kubectl scale deployment <name> --replicas=<count>

# Update image
kubectl set image deployment/<name> <container>=<image>

# Rollout commands
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
```

### Services
```bash
# List services
kubectl get services

# Create service
kubectl expose deployment <name> --port=<port> --type=<type>

# Delete service
kubectl delete service <name>
```

## Monitoring and Debugging

### Logs and Events
```bash
# View pod logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs
kubectl logs <pod-name> -c <container-name>  # Specific container

# View cluster events
kubectl get events
kubectl get events --sort-by='.metadata.creationTimestamp'
```

### Resource Usage
```bash
# Node resource usage
kubectl top node

# Pod resource usage
kubectl top pod
kubectl top pod -n <namespace>
```

### Troubleshooting
```bash
# Check pod status
kubectl get pod <pod-name> -o yaml

# Port forwarding
kubectl port-forward <pod-name> <local-port>:<pod-port>

# Proxy to cluster
kubectl proxy
```

## Configuration and Security

### ConfigMaps and Secrets
```bash
# Create ConfigMap
kubectl create configmap <name> --from-file=<path>
kubectl create configmap <name> --from-literal=key=value

# Create Secret
kubectl create secret generic <name> --from-literal=key=value
kubectl create secret tls <name> --cert=<path/to/cert> --key=<path/to/key>
```

### RBAC
```bash
# View roles
kubectl get roles
kubectl get clusterroles

# View role bindings
kubectl get rolebindings
kubectl get clusterrolebindings
```

## Advanced Operations

### Resource Quotas and Limits
```bash
# View resource quotas
kubectl get resourcequota
kubectl describe resourcequota

# View limit ranges
kubectl get limitrange
kubectl describe limitrange
```

### Namespace Operations
```bash
# Create namespace
kubectl create namespace <name>

# Set default namespace
kubectl config set-context --current --namespace=<name>

# Delete namespace
kubectl delete namespace <name>
```

## Tips and Tricks

### Useful Aliases
```bash
# Common aliases for kubectl
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias krm='kubectl delete'
```

### Output Formatting
```bash
# Different output formats
kubectl get pods -o wide  # Additional details
kubectl get pods -o yaml  # YAML format
kubectl get pods -o json  # JSON format
kubectl get pods -o jsonpath='{.items[*].metadata.name}'  # Custom format
```

!!! tip "Pro Tips"
    - Use `kubectl explain <resource>` to get documentation about resources
    - Use `--dry-run=client -o yaml` to generate resource YAML without creating it
    - Use labels and selectors for efficient resource management
    - Always use namespaces to organize resources
    - Set up auto-completion for easier command line usage

!!! warning "Best Practices"
    - Always use resource limits for containers
    - Implement RBAC policies for security
    - Regularly backup etcd data
    - Use readiness and liveness probes
    - Keep your kubectl version in sync with cluster version

## Additional Resources

- [Official Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubectl Reference Docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)
- [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
