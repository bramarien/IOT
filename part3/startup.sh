#!/bin/bash

# setup docker 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
sudo systemctl status docker


#setup k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

#setup kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl



#setup cluster
k3d cluster create dev-cluster --port 8080:80@loadbalancer --port 443:443@loadbalancer


#setup argoCD
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

kubectl create namespace argocd
kubectl apply -k /vagrant/argocd

kubectl wait --for=condition=Ready pods --all --all-namespaces

kubectl apply -f /vagrant/ingress.yaml

