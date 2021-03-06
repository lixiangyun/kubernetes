#!/usr/bin/bash

# 生成 EncryptionConfig 所需的加密 key
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# 集群主机VIP
export MASTER_VIP="8.1.236.128"

# 集群主机IP地址
export MASTER_IP1=8.1.236.131
export MASTER_IP2=8.1.236.132
export MASTER_IP3=8.1.236.133

# 集群各 IP 对应的 主机名数组
export NODE_NAMES=(kube-master1 kube-master2 kube-master3)

# 集群各机器 IP 数组
export NODE_IPS=($MASTER_IP1 $MASTER_IP2 $MASTER_IP3)

# 集群各 IP 对应的 主机名数组
export AGENT_NAMES=(kube-node4 kube-node5 kube-node6 kube-node7 kube-node8 kube-node9)

# 集群各机器 IP 数组
export AGENT_IPS=(8.1.236.134 8.1.236.135 8.1.236.136 8.1.236.137 8.1.236.138 8.1.236.139)

# etcd 集群服务地址列表
export ETCD_ENDPOINTS="https://${MASTER_IP1}:2379,https://${MASTER_IP2}:2379,https://${MASTER_IP3}:2379"

# etcd 集群间通信的 IP 和端口
export ETCD_NODES="kube-master1=https://${MASTER_IP1}:2380,kube-master2=https://${MASTER_IP2}:2380,kube-master3=https://${MASTER_IP3}:2380"

# kube-apiserver 的反向代理(kube-nginx)地址端口
export KUBE_APISERVER="https://127.0.0.1:8443"

# 生成kubeconfig文件
export KUBE_APISERVER="https://${MASTER_VIP}:8443"




# 节点间互联网络接口名称
export IFACE="ens160"

# etcd 数据目录
export ETCD_DATA_DIR="/opt/k8s/data/etcd/"

# etcd WAL 目录，建议是 SSD 磁盘分区，或者和 ETCD_DATA_DIR 不同的磁盘分区
export ETCD_WAL_DIR="/opt/k8s/wal/etcd/"

# k8s 各组件数据目录
export K8S_DIR="/opt/k8s/k8s"

# docker 数据目录
export DOCKER_DIR="/opt/k8s/docker"

## 以下参数一般不需要修改

# TLS Bootstrapping 使用的 Token，可以使用命令 head -c 16 /dev/urandom | od -An -t x | tr -d ' ' 生成
export BOOTSTRAP_TOKEN="83188f19e558194f4c6405b3339e9139"

# 最好使用 当前未用的网段 来定义服务网段和 Pod 网段

# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
export SERVICE_CIDR="10.254.0.0/16"

# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
export CLUSTER_CIDR="172.30.0.0/16"

# 服务端口范围 (NodePort Range)
export NODE_PORT_RANGE="30000-32767"

# flanneld 网络配置前缀
export FLANNEL_ETCD_PREFIX="/kubernetes/network"

# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
export CLUSTER_KUBERNETES_SVC_IP="10.254.0.1"

# 集群 DNS 服务 IP (从 SERVICE_CIDR 中预分配)
export CLUSTER_DNS_SVC_IP="10.254.0.2"

# 集群 DNS 域名（末尾不带点号）
export CLUSTER_DNS_DOMAIN="cluster.local"

# 将二进制目录 /opt/k8s/bin 加到 PATH 中
export PATH=/opt/k8s/bin:$PATH



alias etcdctl='func() { source 0000.sh; ETCDCTL_API=2 ;/opt/k8s/bin/etcdctl --endpoints=${ETCD_ENDPOINTS} --ca-file=/opt/k8s/cert/ca.pem --cert-file=/opt/k8s/cert/flanneld.pem --key-file=/opt/k8s/cert/flanneld-key.pem $*; }; func'
