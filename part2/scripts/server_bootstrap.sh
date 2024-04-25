#!/bin/bash
apt-get update
export INSTALL_K3S_EXEC="--node-ip 192.168.56.110"
curl -sfL https://get.k3s.io | sh -
kubectl apply -f /vagrant/base/ingress.yaml
kubectl apply -k /vagrant/overlays/a
kubectl apply -k /vagrant/overlays/b
kubectl apply -k /vagrant/overlays/c
