# pwd: /opt/k8s/kubernetes/cluster/addons/dashboard

# 修改: k8s.gcr.io/kubernetes-dashboard-amd64:v1.8.3 -> siriuszg/kubernetes-dashboard-amd64:v1.8.3

vi dashboard-controller.yaml

# port添加：type: NodePort

vi dashboard-service.yaml

# 启动看板服务
kubectl create -f .

# 查看状态

kubectl get deployment kubernetes-dashboard -n kube-system

# CA证书出入，并且添加到信任证书

openssl x509 -outform der -in ca.pem -out ca.der
openssl pkcs12 -export -out admin.pfx -inkey admin-key.pem -in admin.pem -certfile ca.pem

# 创建token

kubectl create sa dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin

ADMIN_SECRET=$(kubectl get secrets -n kube-system | grep dashboard-admin | awk '{print $1}')

DASHBOARD_LOGIN_TOKEN=$(kubectl describe secret -n kube-system ${ADMIN_SECRET} | grep -E '^token' | awk '{print $2}')

echo ${DASHBOARD_LOGIN_TOKEN}


kubectl config set-cluster kubernetes --certificate-authority=/opt/k8s/cert/ca.pem --embed-certs=true --server=https://8.1.236.128:8443 --kubeconfig=dashboard.kubeconfig

# 设置客户端认证参数，使用上面创建的 Token
kubectl config set-credentials dashboard_user --token=${DASHBOARD_LOGIN_TOKEN} --kubeconfig=dashboard.kubeconfig

# 设置上下文参数
kubectl config set-context default --cluster=kubernetes --user=dashboard_user --kubeconfig=dashboard.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=dashboard.kubeconfig


# 浏览器访问看板
https://8.1.236.131:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

# 手工导入dashboard.kubeconfig文件登录看板web服务
