#!/bin/bash

useradd -m k8s



apt-get install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp
apt-get install -y keepalived haproxy
