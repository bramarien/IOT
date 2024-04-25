#!/bin/bash

# Install Vagrant
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
echo "deb http://deb.debian.org/debian/ sid main contrib non-free" >> /etc/apt/sources.list
apt-get update && apt-get install vagrant -y && apt-get install virtualbox -y

# Install Squid
apt-get install squid -y
cat > /etc/squid/squid.conf <<'EOF'
http_access allow localhost manager
http_access deny manager

http_access allow all

cache deny all

http_port 3128
EOF

echo "127.0.0.1  argocd.iot gitlab.iot wil.iot app1.com app2.com app3.com" >> /etc/hosts
systemctl restart squid

# Setup Docker
apt-get update
apt-get install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Install Docker
  apt-get update
  apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

  # Allow user to run docker
  groupadd -f docker
  usermod -aG docker "vagrant"
  newgrp docker


echo "VM is now ready !"
echo ""
echo "You can cd to /vagrant/part1 and type vagrant up to launch the first part"
