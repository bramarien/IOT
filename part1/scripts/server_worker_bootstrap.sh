#!/usr/bin/env bash

# Update packages
apt-get update

  # Define environment variables
    # Version of k3s to download from github
      export INSTALL_K3S_VERSION="v1.28.5+k3s1"
      export K3S_URL="https://192.168.56.110:6443"
      export K3S_TOKEN_FILE="/vagrant/k3s_server_token"

  # Execute install script
  bash /vagrant/scripts/k3s_install.sh --node-ip 192.168.56.111
