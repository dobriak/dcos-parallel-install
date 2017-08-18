#!/bin/bash
sudo lsmod | grep overlay || echo "[WARNING] overlay module not found"
sudo yum install -y yum-utils policycoreutils-python
#pushd /tmp
#    curl -O http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.9-4.el7.noarch.rpm
#    sudo rpm -i container-selinux-2.9-4.el7.noarch.rpm
#popd
#sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo su -c "cat <<EOF >/etc/yum.repos.d/docker.repo
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
EOF
"
sudo yum makecache fast

if [ -d /etc/systemd/system/docker.service.d ]; then
    sudo rm /etc/systemd/system/docker.service.d/*
    sudo systemctl daemon-reload
else
    sudo mkdir -p /etc/systemd/system/docker.service.d
fi

echo "Installing docker"
#sudo yum -y install docker-ce-17.06.0.ce-1.el7.centos
sudo yum -y install docker-engine-1.13.1 docker-engine-selinux-1.13.1
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "restart": "always",
  "graph": "/var/lib/docker",
  "storage-driver": "overlay",
  "host": "fd://"
}
EOF
sudo systemctl start docker
sudo systemctl enable docker
sudo docker info | grep "Storage Driver"
echo "Done"
