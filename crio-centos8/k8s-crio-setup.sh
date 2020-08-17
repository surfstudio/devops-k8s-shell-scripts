#!/bin/env bash

if [[ ! -z "$REQUIRED_VERSION" ]]; then
    
    echo -e ">>> Kubernetes & CRI-O version is $REQUIRED_VERSION\n"

    # Update all packets
    dnf -y update

    # Setup nftables
    firewall-cmd --set-default-zone trusted
    firewall-cmd --reload

    # Setup SELinux
    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    # Setup prerequesites
    modprobe overlay
    modprobe br_netfilter
    echo "br_netfilter" >> /etc/modules-load.d/br_netfilter.conf
    dnf -y install iproute-tc

    # Enable forwarding
    cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
    sysctl --system

    # Setup CRI-O repos
    dnf -y install 'dnf-command(copr)'
    dnf -y copr enable rhcontainerbot/container-selinux
    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_8/devel:kubic:libcontainers:stable.repo
    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$REQUIRED_VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$REQUIRED_VERSION/CentOS_8/devel:kubic:libcontainers:stable:cri-o:$REQUIRED_VERSION.repo

    # Install & configure CRI-O
    dnf -y install cri-o
    sed -i 's/\/usr\/libexec\/crio\/conmon/\/usr\/bin\/conmon/' /etc/crio/crio.conf
    systemctl enable --now crio

    # Setup K8s repo
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

    # Install K8s
    dnf install -y kubelet-$REQUIRED_VERSION* kubeadm-$REQUIRED_VERSION* kubectl-$REQUIRED_VERSION* --disableexcludes=kubernetes

    # Configure K8s
    mkdir /var/lib/kubelet
    cat <<EOF > /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF
    
    cat /dev/null > /etc/sysconfig/kubelet
    cat <<EOF > /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS=--container-runtime=remote --cgroup-driver=systemd --container-runtime-endpoint='unix:///var/run/crio/crio.sock'
EOF
    sudo systemctl enable --now kubelet

    echo -e "\n>>> Now you can initiate K8s with \`kubeadm init\` command"

else

    echo ">>> Please setup Kubernetes & CRI-O version as \$REQUIRED_VERSION"

fi