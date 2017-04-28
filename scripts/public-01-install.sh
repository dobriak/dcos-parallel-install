#!/bin/bash
source cluster.conf
set -ex
mkdir /tmp/dcos
pushd /tmp/dcos
wget http://${BOOTSTRAP}:${BOOTSTRAP_PORT}/dcos_install.sh
sudo bash dcos_install.sh slave_public
popd
echo "Done"