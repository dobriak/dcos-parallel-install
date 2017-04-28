#!/bin/bash
lsmod | grep overlay || echo "[WARNING] overlay module not found"
sudo su -c "tee /etc/yum.repos.d/docker.repo <<- 'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF"
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo su -c "tee /etc/systemd/system/docker.service.d/override.conf <<- 'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --storage-driver=overlay -H fd://
EOF"
echo "Installing docker 1.11.2"
sudo yum install -y docker-engine-1.11.2
sudo systemctl start docker
sudo systemctl enable docker
sudo docker ps
echo "Done"