#!/bin/bash

# Install packages docker kubelet kubeadm
# Ubuntu steps:
#   apt-get update && apt-get install -y apt-transport-https
#   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#   echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
#
#   apt-get install docker.io kubelet kubeadm kubernetes-cni

DOMAIN=myorg.internal

# Run kubeadm to setup kubelet systemd service.
# Check for any warnings and attempt to resolve.
sudo kubeadm init \
    --service-dns-domain $DOMAIN \
    --pod-network-cidr 192.168.100.0/24

# The flag --service-dns-domain doesn't work
# Stop kublet and update manually
# Edit: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# Replace cluster.local with $DOMAIN


# Setup kubectl
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Add Kube-router
kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml

# Allow pods to be scheduled on all nodes
kubectl taint nodes --all node-role.kubernetes.io/master-

# Use hostpath as default storage class
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/rbac.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/deployment.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/storageclass.yaml

# If you want to tear down the cluser use:
# sudo kubeadm reset
