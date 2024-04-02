#!/bin/bash
apt-get update
export INSTALL_K3S_EXEC="--node-ip 192.168.56.110"
curl -sfL https://get.k3s.io | sh -
until [ -f /var/lib/rancher/k3s/server/node-token ]
do
    sleep 1
done
cat /var/lib/rancher/k3s/server/node-token > /vagrant/token
