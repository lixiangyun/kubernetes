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


kubectl config set-cluster kubernetes --certificate-authority=/opt/k8s/cert/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=kubectl.kubeconfig
kubectl config set-credentials admin --client-certificate=/opt/k8s/cert/admin.pem --client-key=/opt/k8s/cert/admin-key.pem --embed-certs=true --kubeconfig=kubectl.kubeconfig
kubectl config set-context kubernetes --cluster=kubernetes --user=admin --kubeconfig=kubectl.kubeconfig
kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig

for node_ip in ${AGENT_IPS[@]}
do
echo ">>> ${node_ip}"
ssh k8s@${node_ip} "mkdir -p ~/.kube"
scp kubectl.kubeconfig k8s@${node_ip}:~/.kube/config
ssh root@${node_ip} "mkdir -p ~/.kube"
scp kubectl.kubeconfig root@${node_ip}:~/.kube/config
done



for node_name in ${AGENT_NAMES[@]}
do
echo ">>> ${node_name}"
# 创建 token
export BOOTSTRAP_TOKEN=$(kubeadm token create --description kubelet-bootstrap-token --groups system:bootstrappers:${node_name} --kubeconfig ~/.kube/config)
# 设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=/opt/k8s/cert/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap --token=${BOOTSTRAP_TOKEN} --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
# 设置上下文参数
kubectl config set-context default --cluster=kubernetes --user=kubelet-bootstrap --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
done


## 分发 bootstrap kubeconfig 文件到所有 worker 节点
for node_name in ${AGENT_NAMES[@]}
do
echo ">>> ${node_name}"
ssh root@${node_name} "mkdir -p /etc/kubernetes && chown k8s:k8s -R /etc/kubernetes/"
scp kubelet-bootstrap-${node_name}.kubeconfig k8s@${node_name}:/etc/kubernetes/kubelet-bootstrap.kubeconfig
done




for node_ip in ${AGENT_IPS[@]}
do
echo ">>> ${node_ip}"
sed -e "s/##NODE_IP##/${node_ip}/" kubelet.config.json.template > kubelet.config-${node_ip}.json
scp kubelet.config-${node_ip}.json root@${node_ip}:/etc/kubernetes/kubelet.config.json
done


for node_name in ${AGENT_NAMES[@]}
do
echo ">>> ${node_name}"
sed -e "s/##NODE_NAME##/${node_name}/" kubelet.service.template >kubelet-${node_name}.service
scp kubelet-${node_name}.service root@${node_name}:/lib/systemd/system/kubelet.service
done

kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --group=system:bootstrappers

# start kubelet on agent nodes

for node_ip in ${AGENT_IPS[@]}
do
echo ">>> ${node_ip}"
ssh root@${node_ip} "mkdir -p /var/lib/kubelet"
ssh root@${node_ip} "swapoff -a"
ssh root@${node_ip} "mkdir -p /var/log/kubernetes && chown -R k8s /var/log/kubernetes"
ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kubelet && systemctl restart kubelet"
done


kubectl apply -f csr-crb.yaml
kubectl get csr


# all agent ready
kubectl get nodes



## 

curl -s --cacert /opt/k8s/cert/ca.pem --cert /opt/k8s/cert/kube-controller-manager.pem --key /opt/k8s/cert/kube-controller-manager-key.pem https://8.1.236.134:10250/metrics

curl -s --cacert /opt/k8s/cert/ca.pem --cert /opt/k8s/cert/admin.pem --key /opt/k8s/cert/admin-key.pem https://8.1.236.134:10250/metrics



## 

kubectl create sa kubelet-api-test
kubectl create clusterrolebinding kubelet-api-test --clusterrole=system:kubelet-api-admin --serviceaccount=default:kubelet-api-test 

SECRET=$(kubectl get secrets | grep kubelet-api-test | awk '{print $1}')
TOKEN=$(kubectl describe secret ${SECRET} | grep -E '^token' | awk '{print $2}')

echo ${TOKEN}

curl -s --cacert /opt/k8s/cert/ca.pem -H "Authorization: Bearer ${TOKEN}" https://8.1.236.134:10250/metrics


keytool -import -v -trustcacerts -alias appmanagement -file /opt/k8s/cert/ca.pem -storepass password -keystore cacerts

source /opt/k8s/bin/environment.sh


## 证书转换，导入游览器
openssl x509 -outform der -in ca.pem -out ca.der
openssl x509 -outform der -in admin.pem -out admin.der
openssl pkcs12 -export -out admin.pfx -inkey admin-key.pem -in admin.pem -certfile ca.pem

# 校验 TLS 证书
openssl x509 -noout -text -in kubernetes.pem
cfssl-certinfo -cert kubernetes.pem
openssl verify -CAfile /opt/k8s/cert/ca.pem /opt/k8s/cert/kubernetes.pem



export KUBE_APISERVER="https://${MASTER_VIP}:8443"

curl -sSL --cacert /opt/k8s/cert/ca.pem --cert /opt/k8s/cert/admin.pem --key /opt/k8s/cert/admin-key.pem ${KUBE_APISERVER}/api/v1/nodes/kube-node4/proxy/configz | jq '.kubeletconfig|.kind="KubeletConfiguration"|.apiVersion="kubelet.config.k8s.io/v1beta1"'


## kube-proxy install on agent

export KUBE_APISERVER="https://${MASTER_VIP}:8443"

kubectl config set-cluster kubernetes --certificate-authority=/opt/k8s/cert/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy --client-certificate=/opt/k8s/cert/kube-proxy.pem --client-key=/opt/k8s/cert/kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-proxy --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

for node_name in ${AGENT_IPS[@]}
do
echo ">>> ${node_name}"
scp kube-proxy.kubeconfig k8s@${node_name}:/etc/kubernetes/
done


for (( i=0; i < 6; i++ ))
do
echo ">>> ${AGENT_NAMES[i]}"
sed -e "s/##NODE_NAME##/${AGENT_NAMES[i]}/" -e "s/##NODE_IP##/${AGENT_IPS[i]}/" kube-proxy.config.yaml.template > kube-proxy-${AGENT_NAMES[i]}.config.yaml
scp kube-proxy-${AGENT_NAMES[i]}.config.yaml root@${AGENT_NAMES[i]}:/etc/kubernetes/kube-proxy.config.yaml
done



for node_name in ${AGENT_NAMES[@]}
do
echo ">>> ${node_name}"
scp kube-proxy.service root@${node_name}:/lib/systemd/system/
done



for node_ip in ${AGENT_IPS[@]}
do
echo ">>> ${node_ip}"
ssh root@${node_ip} "mkdir -p /var/lib/kube-proxy"
ssh root@${node_ip} "mkdir -p /var/log/kubernetes && chown -R k8s:k8s /var/log/kubernetes"
ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-proxy && systemctl restart kube-proxy"
done

# 检查端口状态是否正常

for node_ip in ${AGENT_IPS[@]}
do
echo ">>> ${node_ip}"
ssh k8s@${node_ip} "systemctl status kube-proxy|grep Active"
ssh root@${node_ip} "netstat -lnpt|grep kube-proxy"
done

# check ipvs 
for node_ip in ${AGENT_IPS[@]}
do
echo ">>> ${node_ip}"
ssh root@${node_ip} "ipvsadm -ln"
done

