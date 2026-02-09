#!/bin/bash

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

if ! [ -f /tmp/container.txt ]
then
	echo run ./setup-container.sh before running this script
	exit 4
fi

MYOS=$(hostnamectl | awk '/Operating/ { print $3 }')
OSVERSION=$(hostnamectl | awk '/Operating/ { print $4 }')

which jq || apt install -y jq
KUBEVERSION=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases/latest | jq -r '.tag_name')
KUBEVERSION=${KUBEVERSION%.*}

VERSION=${KUBEVERSION#*.}
PREVIOUSVERSION=$(( VERSION - 1 ))
PREVIOUSVERSION=v1.${PREVIOUSVERSION}


if [ $MYOS = "Ubuntu" ]
then
	echo RUNNING UBUNTU CONFIG
	cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
	br_netfilter
EOF
	
	sudo apt-get update && sudo apt-get install -y apt-transport-https curl
	curl -fsSL https://pkgs.k8s.io/core:/stable:/${PREVIOUSVERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${PREVIOUSVERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sleep 2

	sudo apt-get update
	sudo apt-get install -y kubelet kubeadm kubectl
	sudo apt-mark hold kubelet kubeadm kubectl
	sudo swapoff -a
	
	sudo sed -i 's/\/swap/#\/swap/' /etc/fstab
fi

#sudo cat <<EOF >  /etc/sysctl.d/k8s.conf
#net.bridge.bridge-nf-call-ip6tables = 1
#net.bridge.bridge-nf-call-iptables = 1
#EOF
#sudo sysctl --system

sudo crictl config --set \
    runtime-endpoint=unix:///run/containerd/containerd.sock


# https://docs.projectcalico.org/manifests/calico.yaml 
# the calico plugin (control node only)

