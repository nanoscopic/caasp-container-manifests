#!/bin/sh
kube_dir=/etc/kubernetes/manifests
manifest_dir=/usr/share/caasp-container-manifests
if [ ! -d $kube_dir ]; then
    echo "$kube_dir does not exist" >&2
    echo "make sure kubernetes is installed" >&2
    exit -1
fi
if [ ! -d $manifest_dir ]; then
    echo "$manifest_dir does not exist" >&2
    echo "manifest files are expected to be there" >&2
    exit -2
fi
if [ ! -f $manifest_dir/salt.yaml ]; then
    echo "salt.yaml is not in $manifest_dir" >&2
    exit -3
fi
if [ ! -f $manifest_dir/velum.yaml ]; then
    echo "velum.yaml is not in $manifest_dir" >&2
    exit -3
fi
cp -v $manifest_dir/salt.yaml $kube_dir
cp -v $manifest_dir/velum.yaml $kube_dir

# Make sure that the controller node looks for the local pause image
# TODO: remove this as soon as possible. As an idea, we could use a systemd drop-in unit.
sed -i 's|--config=/etc/kubernetes/manifests|--config=/etc/kubernetes/manifests --pod-infra-container-image=sles12/pause:1.0.0|g' /etc/kubernetes/kubelet

# Make sure etcd listens on 0.0.0.0
sed -i 's@#\?ETCD_LISTEN_PEER_URLS.*@ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380@' /etc/sysconfig/etcd
sed -i 's@#\?ETCD_LISTEN_CLIENT_URLS.*@ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379@' /etc/sysconfig/etcd

if [ "$YAST_IS_RUNNING" = instsys ]; then
    # YaST is configuring controller node
    # enable specific services to ControllerNode
    systemctl enable docker
    systemctl enable kubelet
    systemctl enable etcd
else
    # cloud-init is configuring controller node
    # enable and start specific services to ControllerNode
    systemctl enable --now docker
    systemctl enable --now kubelet
    systemctl enable --now etcd
fi