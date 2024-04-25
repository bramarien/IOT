#!/bin/bash
# Update packages
apt-get update

# Installation of k3s

  # Define environment variables
    # Version of k3s to download from github
      export INSTALL_K3S_VERSION="v1.28.5+k3s1"

  # Execute install script
  bash /vagrant/scripts/k3s_install.sh --bind-address 192.168.56.110 --node-ip 192.168.56.110

# Configure applications
kubectl apply -f /vagrant/confs/base/ingress.yaml
kubectl apply -k /vagrant/confs/overlays/app1
kubectl apply -k /vagrant/confs/overlays/app2
kubectl apply -k /vagrant/confs/overlays/app3

# Wait for applications to be ready
until kubectl wait --for=condition=Ready pods --all --timeout=3m 2>/dev/null;do printf "\rWaiting for applications to be ready";done

echo "Server is now ready !"
echo
echo "Access applications on url: "
echo "http://app1.com:8080/"
echo "http://app2.com:8080/"
echo "http://app3.com:8080/"
