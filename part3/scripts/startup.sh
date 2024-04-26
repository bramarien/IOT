#!/bin/bash

# Setup K3D
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Setup Kubectl
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Setup Cluster
k3d cluster create dev-cluster --port 8080:80@loadbalancer --port 443:443@loadbalancer --port 8888:8888@loadbalancer

# Setup ArgoCD

  # Setup ArgoCD cli
  curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
  rm argocd-linux-amd64

  # Apply Configurations
  kubectl create namespace argocd
  kubectl create namespace dev
  kubectl apply -k /vagrant/part3/confs/argocd

# Wait for ArgoCD to be deployed
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=15m

# Create Ingress Configuration for application
kubectl apply -f /vagrant/part3/confs/ingress.yaml
kubectl apply -f /vagrant/part3/confs/ingressDev.yaml

# Log-in to ArgoCD
until argocd admin initial-password -n argocd 2>/dev/null;do printf "\rWaiting for argocd to be ready...";done
export "ARGO_PASS"="$(argocd admin initial-password -n argocd | head -n1 )"
echo "y" | argocd --grpc-web login argocd.iot --username admin --password "$ARGO_PASS" --insecure

# Deploy Application
argocd  --grpc-web app create dev --repo https://github.com/bramarien/elaignel-argocd.git --path devWil --dest-server https://kubernetes.default.svc --dest-namespace dev --insecure
argocd  --grpc-web app set dev --sync-policy automated --auto-prune --self-heal


until kubectl wait --for=condition=Ready pods --all -n dev --timeout=15m 2>/dev/null; do printf "\rWaiting for Wil's application to be deployed";done

echo "Wil application is now deployed, you can access to it with url: https://wil.iot/"
