#!/usr/bin/env bash

# Update packages
apt-get update

# Installation of k3s

  # Define environment variables
    # Version of k3s to download from github
      export INSTALL_K3S_VERSION="v1.28.5+k3s1"

  # Execute install script
  bash /vagrant/scripts/k3s_install.sh --bind-address 192.168.56.110 --node-ip 192.168.56.110

  until [ -f /var/lib/rancher/k3s/server/node-token ]
  do
      sleep 1
  done

  # Copy token to make it accessible for agent
  cp /var/lib/rancher/k3s/server/node-token /vagrant/k3s_server_token