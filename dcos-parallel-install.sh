#!/bin/bash
source cluster.conf
AWSKEY="${HOME}/.ssh/ec2-default.pem"
#AWSUSER="ec2-user"
AWSUSER="centos"

function parallel_ssh(){
  local members=${1}
  local command=${2}
  tfile=$(mktemp)
  echo "Running ${tfile} on ${members}"
  cat <<EOF >${tfile}
#!/bin/bash
exec > ${tfile}.log.\$\$ 2>&1
echo "Processing member \${1}"
ssh -t -i ${AWSKEY} ${AWSUSER}@\${1} "${command}"
EOF
  chmod +x ${tfile}
  for member in ${members}; do
    if [ ! -z ${3} ]; then 
      echo "Sleeping for ${3}"
      sleep ${3}
    fi
    tmux new-window "${tfile} ${member}"
  done
  #rm ${tfile}.*
}

function parallel_scp(){
  local members=${1}
  local files=${2}

  for member in ${members}; do
    echo "scp ${files} to ${member}"
    tmux new-window "scp -i ${AWSKEY} ${files} ${AWSUSER}@${member}:"
  done
}

function wait_sessions() {
  local max_wait=120
  local interval="30s"
  if [ ! -z ${1} ]; then interval=${1}; fi
  local wins=$(tmux list-sessions | cut -d' ' -f2)
  while [ ! "${wins}" == "1" ]; do
    sleep ${interval}
    (( max_wait-- ))
    wins=$(tmux list-sessions | cut -d' ' -f2)
    echo "Remaining tasks ${wins}"
    if [ ${max_wait} -le 0 ] ; then
      echo "Timeout waiting for all sessions to close."
      tmux kill-server
      exit 1
    fi
  done
}

# Main
if [ ! -f ${AWSKEY} ]; then
    echo "${AWSKEY} key not found."
    exit 1
fi

echo "Starting tmux..."
tmux start-server
tmux new-session -d -s tester

echo "Scanning node public keys for SSH auth ..."
for i in ${AWSNODES}; do
  ssh-keygen -R ${i}
  ssh-keyscan -H ${i} >> ${HOME}/.ssh/known_hosts
done

echo "Making sure we can SSH to all nodes ..."
parallel_ssh "${AWSNODES}" "ls -l"
wait_sessions "5s"

echo "Scp-ing scripts to nodes ..."
parallel_scp "${AWSNODES}" "cluster.conf scripts/all-*"
parallel_scp "${AWSNODESB}" "scripts/boot-03-bootstrap_cust.sh"
parallel_scp "${AWSNODESM}" "scripts/master-*"
parallel_scp "${AWSNODESPRIV}" "scripts/private-*"
parallel_scp "${AWSNODESPUB}" "scripts/public-*"
wait_sessions "5s"

echo "Bootstraping all nodes, part 1"
parallel_ssh "${AWSNODES}" "sudo /home/${AWSUSER}/all-01-bootstrap1.sh"
wait_sessions

#echo "Mounting disks"
#parallel_ssh "${AWSNODESPRIV}" "sudo /home/${AWSUSER}/private-01-mount-disks.sh"
#wait_sessions

echo "---------------------------------------"
echo "Reboot from AWS console then hit Enter"
echo "---------------------------------------"
read

echo "Making sure the nodes came back up"
parallel_ssh "${AWSNODES}" "ls -l"
wait_sessions "5s"

echo "Bootstraping all nodes, part 2"
parallel_ssh "${AWSNODES}" "sudo /home/${AWSUSER}/all-02-bootstrap2.sh"
wait_sessions

echo "Preparing DC/OS binaries ..."
parallel_ssh "${AWSNODESB}" "sudo /home/${AWSUSER}/boot-03-bootstrap_cust.sh"
wait_sessions

echo "Installing master nodes ..."
parallel_ssh "${AWSNODESM}" "sudo /home/${AWSUSER}/master-01-install.sh" "1m"
wait_sessions "1m"
sleep 1m

echo "Installing private and public nodes ..."
parallel_ssh "${AWSNODESPRIV}" "sudo /home/${AWSUSER}/private-02-install.sh"
parallel_ssh "${AWSNODESPUB}" "sudo /home/${AWSUSER}/public-01-install.sh"
wait_sessions "1m"

echo "Shutting down tmux"
tmux kill-server
echo "Done"
