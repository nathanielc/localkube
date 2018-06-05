#!/bin/bash

# Install packages kubelet kubeadm

sudo kubeadm init \
    --service-dns-domain myorg.internal \
    --pod-network-cidr 192.168.100.0/24

# --service-dns-domain doesn't work
# Stop kublet and update manually


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

# To tear down the cluser use
#sudo kubeadm reset
