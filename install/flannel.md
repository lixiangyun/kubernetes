```
./etcdctl --endpoints=http://8.1.236.132:2370 set /kubernetes/network/config '{"Network":"172.30.0.0/16","SubnetLen": 24, "Backend": {"Type": "vxlan"}}'


cd /root
tar -zxf flannel.tgz
cd flannel

source unset_proxy.sh
./flanneld --etcd-endpoints="http://8.1.236.131:2370,http://8.1.236.132:2370,http://8.1.236.133:2370" --etcd-prefix=/kubernetes/network --iface=ens192 > flannel.log 2>&1 &

mkdir /run/flannel

./mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker

cat /run/flannel/docker

vi /lib/systemd/system/docker.service 

EnvironmentFile=-/run/flannel/docker
ExecStart=/usr/bin/dockerd --log-level=error $DOCKER_NETWORK_OPTIONS -H fd:// 

systemctl daemon-reload
service docker restart

ifconfig

vi /etc/rc.local

iptables -P FORWARD ACCEPT

ping 172.30.47.1 -c 10
```
