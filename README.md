# devops-k8s-shell-scripts
Shell scripts for setup Kubernetes


### Install Kubernetes with CRI-O runtime on CentOS 8 (./crio-centos8)

**Prerequisites:**
* I recommend at least one host with minimum 2 cores, 4 GB RAM, 15 GB HDD  
* Installed CentOS 8 (I recommend "Server" profile)

**Install:**  
Setup version of CRI-O and Kubernetes and run with `sudo` (or from `root`):

    sudo bash -c "export REQUIRED_VERSION=1.18 && ./crio-centos8/k8s-crio-setup.sh"
 
### Add user to Kubernetes cluster and generate KUBECONFIG (./k8s-add-user)

**Using:**  
 
    ./kubeconfig-custom.sh <company-username> <ClusterRole>