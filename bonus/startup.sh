#!/bin/bash

# Exit on error and errors in pipelines
set -euo pipefail

export DEBIAN_FRONTEND='noninteractive'

sudo apt-get install squid -y
cat > /etc/squid/squid.conf <<'EOF'
http_access allow localhost manager
http_access deny manager

http_access allow all

cache deny all

http_port 3128
EOF

echo "127.0.0.1  argocd.example.com gitlab.example.com wil.example.com" >> /etc/hosts
systemctl restart squid

# setup docker 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
#sudo systemctl status docker
# curl https://get.docker.com | sudo sh -

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
kubectl create namespace dev
kubectl create namespace gitlab
kubectl apply -k /vagrant/argocd

kubectl wait --for=condition=Ready pods --all -n argocd --timeout=3m

kubectl apply -f /vagrant/ingress.yaml
kubectl apply -f /vagrant/ingressDev.yaml 

argocd admin initial-password -n argocd | head -n 1 > /vagrant/argoPass
chmod +r /vagrant/argoPass
ARGO_PASS=`cat /vagrant/argoPass`


argocd login argocd.example.com --username admin --password $ARGO_PASS --insecure --grpc-web

argocd app create dev --repo https://github.com/bramarien/IOT-app.git --path devWil --dest-server https://kubernetes.default.svc --dest-namespace dev --insecure --grpc-web
argocd app set dev --sync-policy automated --auto-prune --self-heal --grpc-web




# BONUS

#Instal Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#add Gitlab to Helm repo
helm repo add gitlab https://charts.gitlab.io/

#install gitlab
helm install gitlab gitlab/gitlab --set certmanager.install=false --set global.ingress.configureCertmanager="false" -n gitlab

