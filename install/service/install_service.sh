#!/bin/bash

mkdir /opt/k8s/data
mkdir /opt/k8s/data/etcd
chown k8s:k8s -R /opt/k8s/*

# install etcd service all master nodes

cp etcd.service /lib/systemd/system/ -rf
systemctl daemon-reload
systemctl enable etcd
service etcd start



ETCDCTL_API=3 /opt/k8s/bin/etcdctl --endpoints=https://8.1.236.131:2379 --cacert=/opt/k8s/cert/ca.pem --cert=/opt/k8s/cert/etcd.pem --key=/opt/k8s/cert/etcd-key.pem endpoint health
ETCDCTL_API=3 /opt/k8s/bin/etcdctl --endpoints=https://8.1.236.132:2379 --cacert=/opt/k8s/cert/ca.pem --cert=/opt/k8s/cert/etcd.pem --key=/opt/k8s/cert/etcd-key.pem endpoint health
ETCDCTL_API=3 /opt/k8s/bin/etcdctl --endpoints=https://8.1.236.133:2379 --cacert=/opt/k8s/cert/ca.pem --cert=/opt/k8s/cert/etcd.pem --key=/opt/k8s/cert/etcd-key.pem endpoint health


source /opt/k8s/bin/environment.sh


alias etcdctl='func() { source 0000.sh; ETCDCTL_API=2 ;/opt/k8s/bin/etcdctl --endpoints=${ETCD_ENDPOINTS} --ca-file=/opt/k8s/cert/ca.pem --cert-file=/opt/k8s/cert/flanneld.pem --key-file=/opt/k8s/cert/flanneld-key.pem $*; }; func'


ETCDCTL_API=2 /opt/k8s/bin/etcdctl --endpoints=${ETCD_ENDPOINTS} --ca-file=/opt/k8s/cert/ca.pem --cert-file=/opt/k8s/cert/flanneld.pem --key-file=/opt/k8s/cert/flanneld-key.pem set ${FLANNEL_ETCD_PREFIX}/config '{"Network":"'${CLUSTER_CIDR}'", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'

ETCDCTL_API=2 /opt/k8s/bin/etcdctl --endpoints=${ETCD_ENDPOINTS} --ca-file=/opt/k8s/cert/ca.pem --cert-file=/opt/k8s/cert/flanneld.pem --key-file=/opt/k8s/cert/flanneld-key.pem get ${FLANNEL_ETCD_PREFIX}/config


# install flanneld service all master nodes


cp flanneld.service /lib/systemd/system/ -rf
systemctl daemon-reload
systemctl enable flanneld
service flanneld start



etcdctl get ${FLANNEL_ETCD_PREFIX}/config
etcdctl ls ${FLANNEL_ETCD_PREFIX}/subnets
etcdctl get ${FLANNEL_ETCD_PREFIX}/subnets/172.30.30.0-24



# start haproxy service all master nodes

cp haproxy.cfg /etc/haproxy
systemctl restart haproxy

systemctl status haproxy

netstat -nap | grep haproxy

# start keepalived master service on matser
cp keepalived-master.conf /etc/keepalived/keepalived.conf
systemctl restart keepalived
systemctl status keepalived

ip addr show ens160

# start keepalived backup service on matser
cp keepalived-backup.conf /etc/keepalived/keepalived.conf
systemctl restart keepalived
systemctl status keepalived

ping -c 1 ${MASTER_VIP}

## install k8s apt server on matser nodes

source /opt/k8s/bin/environment.sh
mkdir -p /etc/kubernetes/
mkdir -p /var/log/kubernetes

cp encryption-config.yaml /etc/kubernetes/encryption-config.yaml 
cp kube-apiserver.service /lib/systemd/system/ -rf

chown -R k8s:k8s /var/log/kubernetes
chown -R k8s:k8s /etc/kubernetes/

systemctl daemon-reload
systemctl enable kube-apiserver
systemctl restart kube-apiserver
systemctl status kube-apiserver


ETCDCTL_API=3
etcdctl get /registry/ --prefix --keys-only

alias etcdctlv3='func() { source 0000.sh; ETCDCTL_API=3 ;/opt/k8s/bin/etcdctl --endpoints=${ETCD_ENDPOINTS} --ca-file=/opt/k8s/cert/ca.pem --cert-file=/opt/k8s/cert/flanneld.pem --key-file=/opt/k8s/cert/flanneld-key.pem $*; }; func'


# check k8s cluster infomation
kubectl cluster-info
kubectl get all --all-namespaces
kubectl get componentstatuses

# 授予 kubernetes 证书访问 kubelet API 的权限
kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user kubernetes


# install kube-controller-manager service on master nodes;

# sync kube-controller-manager.kubeconfig for matser

cp kube-controller-manager.service /lib/systemd/system/ -rf
mkdir -p /var/log/kubernetes
chown -R k8s:k8s /var/log/kubernetes

systemctl daemon-reload 
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager
systemctl status kube-controller-manager

curl -s --cacert /opt/k8s/cert/ca.pem https://127.0.0.1:10252/metrics | head

kubectl get endpoints kube-controller-manager --namespace=kube-system -o yaml


# install kube-scheduler service on master nodes;
cp kube-scheduler.service /lib/systemd/system/ -rf
mkdir -p /var/log/kubernetes
chown -R k8s:k8s /var/log/kubernetes

systemctl daemon-reload 
systemctl enable kube-scheduler
systemctl restart kube-scheduler
systemctl status kube-scheduler


netstat -lnpt|grep kube-sche

curl -s http://127.0.0.1:10251/metrics | head


kubectl get endpoints kube-scheduler --namespace=kube-system -o yaml