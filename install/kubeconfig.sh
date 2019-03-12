#!/bin/bash

source /opt/k8s/bin/environment.sh

mkdir -P /etc/kubernetes/


kubectl config set-cluster kubernetes --certificate-authority=/opt/k8s/cert/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=kubectl.kubeconfig
kubectl config set-credentials admin --client-certificate=/opt/k8s/cert/admin.pem --client-key=/opt/k8s/cert/admin-key.pem --embed-certs=true --kubeconfig=kubectl.kubeconfig
kubectl config set-context kubernetes --cluster=kubernetes --user=admin --kubeconfig=kubectl.kubeconfig
kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig

for node_ip in ${NODE_IPS[@]}
do
echo ">>> ${node_ip}"
ssh k8s@${node_ip} "mkdir -p ~/.kube"
scp kubectl.kubeconfig k8s@${node_ip}:~/.kube/config
ssh root@${node_ip} "mkdir -p ~/.kube"
scp kubectl.kubeconfig root@${node_ip}:~/.kube/config
done



kubectl config set-cluster kubernetes --certificate-authority=/opt/k8s/cert/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-credentials system:kube-controller-manager --client-certificate=/opt/k8s/cert/kube-controller-manager.pem --client-key=/opt/k8s/cert/kube-controller-manager-key.pem --embed-certs=true --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-context system:kube-controller-manager --cluster=kubernetes --user=system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig


source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
do
echo ">>> ${node_ip}"
scp kube-controller-manager.kubeconfig k8s@${node_ip}:/etc/kubernetes/
done



kubectl config set-cluster kubernetes --certificate-authority=/opt/k8s/cert/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-credentials system:kube-scheduler --client-certificate=/opt/k8s/cert/kube-scheduler.pem --client-key=/opt/k8s/cert/kube-scheduler-key.pem --embed-certs=true --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-context system:kube-scheduler --cluster=kubernetes --user=system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig


source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
do
echo ">>> ${node_ip}"
scp kube-scheduler.kubeconfig k8s@${node_ip}:/etc/kubernetes/
done