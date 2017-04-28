#!/bin/bash
source cluster.conf
IPDETECT="curl -fsSL http://169.254.169.254/latest/meta-data/local-ipv4"
IPDETECT_PUB="curl -fsSL https://ipinfo.io/ip"

echo "Getting 1.8.8 installer"
wget https://downloads.dcos.io/dcos/stable/commit/602edc1b4da9364297d166d4857fc8ed7b0b65ca/dcos_generate_config.sh

sudo systemctl stop firewalld && sudo systemctl disable firewalld
echo "Installing nginx"
sudo docker pull nginx

RESOLVER_IP=$(cat /etc/resolv.conf | grep nameserver | cut -d' ' -f2)
echo "Using ${RESOLVER_IP} as resolver"
BOOTSTRAP_IP=$(${IPDETECT})

mkdir genconf

echo "Writing ip-detect"
cat <<EOF >genconf/ip-detect
#!/bin/bash
set -o nounset -o errexit
${IPDETECT}
EOF

echo "Writing ip-detect-public"
cat <<EOF >genconf/ip-detect-public
#!/bin/bash
set -o nounset -o errexit
${IPDETECT_PUB}
EOF

EXTRA_MASTERS=""
if [ -n "${MASTER2}" ] && [ -n "${MASTER3}" ]; then
  EXTRA_MASTERS="
- ${MASTER2}
- ${MASTER3}
"
fi

echo "Writing config.yaml"
cat <<EOF >genconf/config.yaml
bootstrap_url: http://${BOOTSTRAP_IP}:${BOOTSTRAP_PORT}
cluster_name: DCOS188
exhibitor_storage_backend: static
master_discovery: static
telemetry_enabled: true
security: permissive
rexray_config_method: file
rexray_config_filename: rexray.yaml
ip_detect_public_filename: genconf/ip-detect-public
master_list:
- ${MASTER1}
${EXTRA_MASTERS}
resolvers:
- ${RESOLVER_IP}
superuser_username: bootstrapuser
EOF

echo "Writing rexray.yaml"
cat <<EOF >genconf/rexray.yaml
loglevel: info
storageDrivers:
  - ec2
volume:
  unmount:
    ignoreusedcount: true
EOF

echo "Setting superuser password to ${SUPASSWORD}"
sudo bash dcos_generate_config.sh --set-superuser-password ${SUPASSWORD}

echo "Generating binaries"
sudo bash dcos_generate_config.sh

echo "Running nginx on http://${BOOTSTRAP_IP}:${BOOTSTRAP_PORT}"
sudo docker run -d -p ${BOOTSTRAP_PORT}:80 -v $PWD/genconf/serve:/usr/share/nginx/html:ro nginx

echo "Done"
