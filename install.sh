#!/bin/bash

# Install packages docker kubelet kubeadm
# Ubuntu steps:
#   apt-get update && apt-get install -y apt-transport-https
#   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#   echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
#
#   apt-get install docker.io kubelet kubeadm kubernetes-cni

set -e

DOMAIN=${DOMAIN-slate.internal}
#IP=$(hostname --ip-address | awk '{print $1}')

bind_dirs='/etc/kubernetes/pki /etc/kubernetes/scheduler.conf /etc/ssl/certs /var/lib/etcd'
for dir in $bind_dirs
do
    sudo umount $dir $dir || true
done

sudo kubeadm reset

sudo mkdir -p /etc/systemd/system/kubelet.service.d/
sudo cp ./override.conf /etc/systemd/system/kubelet.service.d/

sudo mkdir -p /etc/kubernetes
sudo cp ./kubelet.system.config /etc/kubernetes/

sudo systemctl daemon-reload

# Bind paths as workaround to https://github.com/moby/moby/issues/37032
#for dir in $bind_dirs
#do
#    sudo touch $dir
#    sudo mount --bind $dir $dir
#done

# Run kubeadm to setup kubelet systemd service.
# Check for any warnings and attempt to resolve.
sudo kubeadm init \
    --kubernetes-version 1.10.3 \
    --apiserver-advertise-address 127.0.0.1 \
    --apiserver-cert-extra-sans 127.0.0.1 \
    --service-dns-domain $DOMAIN \
    --service-cidr 10.42.0.0/16 \
    --pod-network-cidr 192.168.100.0/24 \
    --ignore-preflight-errors=Swap
    #--node-name localhost \

# The flag --service-dns-domain doesn't work
# Stop kublet and update manually
# Edit: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl stop kubelet
sudo sed -i "s/cluster\.local/$DOMAIN/" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo sed -i "s/10\.96\.0\.10/10.42.0.10/" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
#sudo sed -i "s/KUBELET_DNS_ARGS=/KUBELET_DNS_ARGS=--hostname-override 127.0.0.1 /" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
#if [ -z $IP ]
#then
#    sudo find /etc/kubernetes -type f | xargs sudo sed -i "s/$IP/127.0.0.1/"
#fi
sudo systemctl daemon-reload
sudo systemctl start kubelet


# Setup kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /root
sudo cp /etc/kubernetes/admin.conf /root/.kube/config

# Reapply manifests

#for m in $(sudo ls /etc/kubernetes/manifests)
#do
#    sudo kubectl apply -f /etc/kubernetes/manifests/$m
#done

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
