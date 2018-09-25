#!/bin/bash

# Install packages docker kubelet kubeadm

set -e

# Pick a domain for the cluster DNS
DOMAIN=${DOMAIN-cluster.local}
# Pick an IP to bind to, kubeadm/kubelet will not use a 127.0.0.1/8 IP, so it needs to be a different IP
# By default we use 10.1.1.1 since its in the private 10.0.0.0/8 range.
IP=${IP-10.1.1.1}
# Bind the new IP to an interface, this interface should be stable, meaning it does not go away when WiFi is turned off/on or when ethernet cabels are unplugged/plugged.
# By default we use the loopback interface since that is typically stable.
INTERFACE=${INTERFACE-lo}


# Setup static IP for k8s on a stable interface
sudo cp ./k8s-ip.env /etc/default/k8s-ip
sudo sed -i "s/IP=.*/IP=$IP/" /etc/default/k8s-ip
sudo sed -i "s/INTERFACE=.*/INTERFACE=$INTERFACE/" /etc/default/k8s-ip

sudo cp ./k8s-ip.service /etc/systemd/system/k8s-ip.service
sudo systemctl daemon-reload
sudo systemctl enable k8s-ip.service
sudo systemctl start k8s-ip.service

# Reset any existing kubelet config
sudo kubeadm reset

# Setup systemd config for kubelet
sudo mkdir -p /etc/default
sudo cp ./kubelet.env /etc/default/kubelet

sudo mkdir -p /etc/systemd/system/kubelet.service.d/
sudo cp ./kubelet.override.conf /etc/systemd/system/kubelet.service.d/

sudo mkdir -p /etc/kubernetes
sudo cp ./kubelet.system.config /etc/kubernetes/
# The --service-dns-domain flag below does not completely work so we workaround it by doing its work for it here.
sudo sed -i "s/clusterDomain:.*/clusterDomain: $DOMAIN/" /etc/kubernetes/kubelet.system.config
sudo sed -i "s/address:.*/address: $IP/" /etc/kubernetes/kubelet.system.config

sudo systemctl daemon-reload

# Run kubeadm to setup kubelet systemd service.
# Check for any warnings and attempt to resolve.
sudo kubeadm init \
    -v 5 \
    --kubernetes-version 1.11.2 \
    --apiserver-advertise-address $IP \
    --apiserver-cert-extra-sans $IP \
    --service-dns-domain $DOMAIN \
    --service-cidr 10.42.0.0/16 \
    --pod-network-cidr 192.168.100.0/24 \
    --ignore-preflight-errors=Swap \
    --feature-gates=CoreDNS=false

# Setup kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
#sed -i "s/$IP/127.0.0.1/" $HOME/.kube/config


# Add Kube-router
kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml

# Allow pods to be scheduled on all nodes
kubectl taint nodes --all node-role.kubernetes.io/master-

# Use hostpath as default storage class
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/rbac.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/deployment.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/storageclass.yaml

