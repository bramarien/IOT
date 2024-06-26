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

echo "127.0.0.1  argocd.iot gitlab.iot wil.iot" >> /etc/hosts
systemctl restart squid

# Setup Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce

# Setup K3D
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Setup Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Setup Cluster
k3d cluster create dev-cluster --port 8080:80@loadbalancer --port 443:443@loadbalancer

# Setup ArgoCD
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

kubectl create namespace argocd
kubectl create namespace dev
kubectl create namespace gitlab
kubectl apply -k /vagrant/confs/argocd

until kubectl wait --for=condition=Ready pods --all -n argocd --timeout=5m ; do printf "\rWaiting for Argocd to be Ready" ; done

kubectl apply -f /vagrant/confs/ingress.yaml
kubectl apply -f /vagrant/confs/ingressDev.yaml
kubectl apply -f /vagrant/confs/ingressGitlab.yaml

# Instal Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#Add Gitlab to Helm repo
helm repo add gitlab https://charts.gitlab.io/

# Install Gitlab
helm install gitlab gitlab/gitlab --set certmanager.install=false --set global.ingress.configureCertmanager="false" -n gitlab

kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode > /vagrant/gitPW

until kubectl wait --timeout 15m --for condition=Available deployment -n gitlab --all 2>/dev/null; do printf "\rWaiting for Gitlab to be Ready" ; done

# Setup Git
git clone https://github.com/bramarien/IOT-app.git
cd IOT-app
PW="$(cat /vagrant/gitPW)"
git config http.sslVerify false
git remote add iot https://root:$PW@gitlab.iot/root/devWil
git push iot

#argocd App setup
argocd admin initial-password -n argocd | head -n 1 > /vagrant/argoPW
chmod a+r /vagrant/argoPW

echo "Server is now installed with gitlab (gitlab.iot) and ArgoCD (argocd.iot)"
echo ""
echo "A demo project has been pushed on https://gitlab.iot/root/devWil, you can deploy it on ArgoCD by making
it public and launching the script scripts/argocd_app_create.sh"
