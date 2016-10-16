#!/bin/bash

function get_local_ip {
    default_interface=$(ip link show  | grep -v '^\s' | cut -d':' -f2 | sed 's/ //g' | grep -v lo | head -1)
    address=$(ip addr show label $default_interface scope global | awk '$1 == "inet" { print $2,$4}')
    ip=$(echo $address | awk '{print $1 }')
    ip=${ip%%/*}
    echo $ip
}

function get_discovery_token {
    CLUSTER_SIZE=2
    `curl https://discovery.etcd.io/new?size=${CLUSTER_SIZE}`
}

function install_etcd {
    ETCD_VER=v3.0.12
    DOWNLOAD_URL=https://github.com/coreos/etcd/releases/download
    curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz \
 	-o etcd-${ETCD_VER}-linux-amd64.tar.gz
    mkdir -p etcd && tar xzvf etcd-${ETCD_VER}-linux-amd64.tar.gz -C etcd --strip-components=1
    etcd/etcd --version
    cp etcd/etcd etcd/etcdctl /usr/bin
}

function install_flannel {
    FLANNEL_VER=v0.6.1
    DOWNLOAD_URL=https://github.com/coreos/flannel/releases/download/
    curl -L ${DOWNLOAD_URL}/${FLANNEL_VER}/flannel-${FLANNEL_VER}-linux-amd64.tar.gz \
    	-o flannel-${FLANNEL_VER}-linux-amd64.tar.gz
    mkdir -p flannel && tar xzvf flannel-${FLANNEL_VER}-linux-amd64.tar.gz -C flannel 
    flannel/flanneld --version
    cp flannel/flanneld flannel/mk-docker-opts.sh /usr/bin
}

function start_etcd {
    local_ip=$(get_local_ip)
    nohup etcd -name infra0 \
      	-initial-advertise-peer-urls http://${local_ip}:2380 \
       	-listen-peer-urls http://${local_ip}:2380 \
        -listen-client-urls http://${local_ip}:2379,http://127.0.0.1:2379 \
      	-advertise-client-urls http://${local_ip}:2379 \
 	-discovery ${DISCOVER_TOKEN} \
	--data-dir /usr/local/kubernete_test/flanneldata  \
	>> /usr/local/kubernete_test/logs/etcd.log 2>&1 &
}

CLUSTER_SIZE=2
DISCOVER_TOKEN=https://discovery.etcd.io/8bbe4bcabcea50cb136f797b667b55f2
mkdir -p /usr/local/kubernete_test/logs

#install_etcd
#install_flannel
start_etcd
