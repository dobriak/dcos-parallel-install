#!/bin/bash
sudo yum install -y wget vim net-tools ipset telnet unzip
sudo groupadd nogroup
echo "Enable OverlayFS"
sudo tee /etc/modules-load.d/overlay.conf <<-'EOF'
overlay
EOF
echo "Disable SELinux"
sudo su -c "sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config"
echo "Please reboot from the AWS console, then run bootstrap_rh.sh"
echo "Done"