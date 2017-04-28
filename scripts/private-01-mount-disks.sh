#!/bin/bash
for i in xvdb xvdc xvdd; do mkfs -t ext4 /dev/$i ; done
for i in 0 1 2; do mkdir -p /dcos/volume${i} ; done
mount /dev/xvdb /dcos/volume0 
mount /dev/xvdc /dcos/volume1 
mount /dev/xvdd /dcos/volume2
cp /etc/fstab /etc/fstab.orig
echo '/dev/xvdb  /dcos/volume0 ext4 defaults 0 0' >> /etc/fstab
echo '/dev/xvdc  /dcos/volume1 ext4 defaults 0 0' >> /etc/fstab
echo '/dev/xvdd  /dcos/volume2 ext4 defaults 0 0' >> /etc/fstab
mount -a
echo "Done mounting EBS volumes"