#!/bin/bash
apt-get update
export INSTALL_K3S_EXEC="--node-ip 192.168.56.110"
curl -sfL https://get.k3s.io | sh -
kubectl apply -f /vagrant/confs/base/ingress.yaml
kubectl apply -k /vagrant/confs/overlays/app1
kubectl apply -k /vagrant/confs/overlays/app2
kubectl apply -k /vagrant/confs/overlays/app3
