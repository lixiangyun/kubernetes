#!/bin/bash

apt update
apt install -y conntrack ipvsadm ipset jq iptables curl sysstat libseccomp2 libseccomp-dev


# 环境准备

systemctl stop firewalld
systemctl disable firewalld

echo "/sbin/iptables -P FORWARD ACCEPT" >> /etc/rc.local

iptables -F
iptables -X
iptables -F -t nat
iptables -X -t nat
iptables -P FORWARD ACCEPT


# install flannel.service 
source /opt/k8s/bin/environment.sh

cp flanneld.service /lib/systemd/system/ -rf
systemctl daemon-reload
systemctl enable flanneld
service flanneld start

etcdctl get ${FLANNEL_ETCD_PREFIX}/config
etcdctl ls ${FLANNEL_ETCD_PREFIX}/subnets

# install docker.service 

cp docker.service /lib/systemd/system -rf

systemctl daemon-reload
systemctl enable docker
systemctl restart docker
systemctl status docker


for intf in /sys/devices/virtual/net/docker0/brif/*
do
echo 1 > $intf/hairpin_mode; 
done

sysctl -p /etc/sysctl.d/kubernetes.conf

# install kubelet

source /opt/k8s/bin/environment.sh

##
# 集群各 IP 对应的 主机名数组
export AGENT_NAMES=(kube-node4 kube-node5 kube-node6 kube-node7 kube-node8 kube-node9)

# 集群各机器 IP 数组
export AGENT_IPS=(8.1.236.134 8.1.236.135 8.1.236.136 8.1.236.137 8.1.236.138 8.1.236.139)

for node_name in ${AGENT_NAMES[@]}
do
echo ">>> ${node_name}"
# 创建 token
export BOOTSTRAP_TOKEN=$(kubeadm token create --description kubelet-bootstrap-token --groups system:bootstrappers:${node_name} --kubeconfig ~/.kube/config)
# 设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=/opt/k8s/cert/ca.pem --embed-certs=true --server=${MASTER_VIP} --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap --token=${BOOTSTRAP_TOKEN} --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
# 设置上下文参数
kubectl config set-context default --cluster=kubernetes --user=kubelet-bootstrap --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
done

