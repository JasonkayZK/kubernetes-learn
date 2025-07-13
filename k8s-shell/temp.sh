docker pull registry.aliyuncs.com/google_containers/kube-apiserver:v1.28.2
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:v1.28.2
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.28.2
docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.28.2
docker pull registry.aliyuncs.com/google_containers/pause:3.9
docker pull registry.aliyuncs.com/google_containers/etcd:3.5.9-0
docker pull registry.aliyuncs.com/google_containers/coredns:v1.10.1


docker tag registry.aliyuncs.com/google_containers/kube-apiserver:v1.28.2 registry.k8s.io/kube-apiserver:v1.28.2
docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:v1.28.2 registry.k8s.io/kube-controller-manager:v1.28.2
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:v1.28.2 registry.k8s.io/kube-scheduler:v1.28.2
docker tag registry.aliyuncs.com/google_containers/kube-proxy:v1.28.2 registry.k8s.io/kube-proxy:v1.28.2
docker tag registry.aliyuncs.com/google_containers/pause:3.9 registry.k8s.io/pause:3.9
docker tag registry.aliyuncs.com/google_containers/etcd:3.5.9-0 registry.k8s.io/etcd:3.5.9-0
docker tag registry.aliyuncs.com/google_containers/coredns:v1.10.1 registry.k8s.io/coredns/coredns:v1.10.1



docker pull docker.io/calico/node:v3.24.5
docker pull docker.io/calico/cni:v3.24.5
docker pull docker.io/calico/kube-controllers:v3.24.5




kubeadm init --kubernetes-version=1.28.2 \
--apiserver-advertise-address=192.168.1.20 \
--image-repository registry.aliyuncs.com/google_containers \
--service-cidr=172.15.0.0/16 --pod-network-cidr=172.16.0.0/16 \
--cri-socket unix:///var/run/cri-dockerd.sock


