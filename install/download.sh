#!/bin/bash

mkdir etcd
wget https://github.com/coreos/etcd/releases/download/v3.3.7/etcd-v3.3.7-linux-amd64.tar.gz --no-check-certificate
tar -zxf etcd-v3.3.7-linux-amd64.tar.gz -C etcd
mv etcd/etcd* /opt/k8s/bin
rm -rf etcd*


mkdir flannel
wget https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz  --no-check-certificate
tar -xzvf flannel-v0.10.0-linux-amd64.tar.gz -C flannel
mv flannel/* /opt/k8s/bin
rm -rf flannel*






