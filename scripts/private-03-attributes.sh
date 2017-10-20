#!/bin/bash
if [ -z "${1}" ]; then
    echo "Missing argument. Format:"
    echo "  ${0} key1:value1[,keyX:valueX,...] [-f]"
    exit 1
fi
if [ -f /var/lib/dcos/mesos-slave-common ]; then
    if [ "${2}" != "-f" ]; then
        echo "mesos-slave-common exists. Contents:"
        cat /var/lib/dcos/mesos-slave-common
        echo "Use -f to overwrite."
        exit 1
    fi
fi

sudo su -c "echo MESOS_ATTRIBUTES=${1} > /var/lib/dcos/mesos-slave-common"
sudo rm -rf /var/lib/mesos/slave/meta/slaves/latest
sudo systemctl restart dcos-mesos-slave.service
echo "Attributes set:${1}"
