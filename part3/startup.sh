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
kubectl create namespace dev
kubectl apply -k /vagrant/argocd

kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=15m

kubectl apply -f /vagrant/ingress.yaml
kubectl apply -f /vagrant/ingressDev.yaml 

argocd admin initial-password -n argocd > /vagrant/argoPassNoClean
echo $(head -n 1 /vagrant/argoPassNoClean) > /vagrant/argoPass ; rm /vagrant/argoPassNoClean
echo "192.168.56.110  argocd.example.com wil.example.com" >> /etc/hosts
chmod 777 /vagrant/argoPass
export ARGO_PASS=`cat /vagrant/argoPass`


argocd login argocd.example.com --username admin --password $ARGO_PASS --insecure

argocd app create dev --repo https://github.com/bramarien/IOT-app.git --path devWil --dest-server https://kubernetes.default.svc --dest-namespace dev --insecure
argocd app set dev --sync-policy automated --auto-prune --self-heal
