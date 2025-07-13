# Ref: 
# - https://h2c.tech/p/%E5%88%A9%E7%94%A8kubeadm%E7%A6%BB%E7%BA%BF%E6%90%AD%E5%BB%BAk8s/
#

# 初始化系统（Master、Worker）

export MASTER_IP="192.168.31.58"
export WORKER_IP="192.168.31.232"

echo "export MASTER_IP=$MASTER_IP" >> ~/.bashrc
echo "export WORKER_IP=$WORKER_IP" >> ~/.bashrc
source ~/.bashrc
# echo $MASTER_IP

hostnamectl set-hostname k8s-master # master
hostnamectl set-hostname k8s-worker # worker

systemctl stop firewalld
systemctl disable firewalld

echo "$MASTER_IP k8s-master" >> /etc/hosts
echo "$WORKER_IP k8s-worker" >> /etc/hosts

vi /etc/fstab # 删除swap
reboot # free -h


# 复制镜像内容（master, worker）

mount -o loop chinaskills_cloud_paas_v2.0.2.iso /mnt/
cp -rfv /mnt/* /opt/
umount /mnt/




# 安装依赖（master, worker）

## 源：https://developer.aliyun.com/mirror/centos/

mkdir /opt/repo-bak/
mv /etc/yum.repos.d/* /opt/repo-bak/
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache

cd /opt/dependencies
tar -zxvf base-rpms.tar.gz -C /opt/dependencies
yum install /opt/dependencies/base-rpms/*.rpm

## 关闭cgroup！
systemctl start docker

vi /etc/docker/daemon.json
{
  "exec-opts":["native.cgroupdriver=systemd"],
  "registry-mirrors": [
    "https://docker.chenby.cn"
  ]
}
systemctl restart docker
systemctl enable docker

systemctl restart kubelet
systemctl enable kubelet

# 安装K8s

## 导入镜像（master, worker）
cd /opt
tar -zxvf kubernetes.tar.gz -C /opt/
docker load -i /opt/kubernetes/images/k8s-images.tar.gz # docker images

## 生成K8S配置

cd /opt/kubernetes
kubeadm config print init-defaults > kubeadm.yaml
sed -i "s/kubernetesVersion:/#kubernetesVersion:/" kubeadm.yaml
sed -i "s/advertiseAddress: 1.2.3.4/advertiseAddress: $(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' | awk 'NR<2{print $1}')/" kubeadm.yaml
sed -i "s/name: node/name: k8s-master/" kubeadm.yaml

# https://www.hyhblog.cn/2021/02/21/k8s-flannel-pod-cidr-not-assigned/
vi kubeadm.yaml # 增加networking.podNetworkCidr 配置

# Example:
#
# apiVersion: kubeadm.k8s.io/v1beta3
# kind: InitConfiguration
# localAPIEndpoint:
#   advertiseAddress: 192.168.31.58
#   bindPort: 6443
# nodeRegistration:
#   criSocket: /var/run/dockershim.sock
#   imagePullPolicy: IfNotPresent
#   name: k8s-master
#   taints: null
# bootstrapTokens:
# - groups:
#   - system:bootstrappers:kubeadm:default-node-token
#   token: abcdef.0123456789abcdef
#   ttl: 24h0m0s
#   usages:
#   - signing
#   - authentication
# ---
# apiVersion: kubeadm.k8s.io/v1beta3
# kind: ClusterConfiguration
# certificatesDir: /etc/kubernetes/pki
# clusterName: kubernetes
# imageRepository: k8s.gcr.io
# networking:
#   dnsDomain: cluster.local
#   serviceSubnet: 10.96.0.0/12
#   podNetworkCidr: 172.18.0.0/16  # 添加这一行
# etcd:
#   local:
#     dataDir: /var/lib/etcd
# apiServer:
#   timeoutForControlPlane: 4m0s
# controllerManager: {}
# dns: {}
# scheduler: {}
# kubernetesVersion: v1.22.1


echo "kubernetesVersion: $(kubeadm version -o short)" >> kubeadm.yaml

kubeadm init --config kubeadm.yaml
# 出错使用 kubeadm reset 复原！

# 完成后输出如下内容：

# Your Kubernetes control-plane has initialized successfully!
#
# To start using your cluster, you need to run the following as a regular user:
#
#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config
#
# Alternatively, if you are the root user, you can run:
#
#   export KUBECONFIG=/etc/kubernetes/admin.conf
#
# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/
#
# Then you can join any number of worker nodes by running the following on each as root:
#
# kubeadm join 192.168.31.58:6443 --token abcdef.0123456789abcdef \
#         --discovery-token-ca-cert-hash sha256:fb57fad7226f767269c7783a6fd69790e90095b463febfdaf555e70463d137b5 

echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
echo "alias k='kubectl'" >> ~/.bashrc
source ~/.bashrc


## 安装网络插件Flannel

cd /opt/kubernetes/manifests
cat kube-flannel.yaml |grep image # 查看所需镜像
docker images |grep flannel # 查看拥有的镜像

kubectl apply -f kube-flannel.yaml # watch kubectl get po -A
# Ref：https://www.hyhblog.cn/2021/02/21/k8s-flannel-pod-cidr-not-assigned/
# 如果前面没有配置CIDR，执行：kubectl patch node k8s-master -p '{"spec":{"podCIDR":"172.18.0.0/24"}}'



## Worker加入集群(Worker)

echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables # worker

# 这是kube init的时候系统打印的
# 忘记了就去主节点用这个打印出来
# kubeadm token create --print-join-command
kubeadm join 192.168.31.58:6443 --token abcdef.0123456789abcdef    \
  --discovery-token-ca-cert-hash sha256:fb57fad7226f767269c7783a6fd69790e90095b463febfdaf555e70463d137b5


# 成功输出：
#
# This node has joined the cluster:
# * Certificate signing request was sent to apiserver and a response was received.
# * The Kubelet was informed of the new secure connection details.

# Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

# master节点查看
kubectl get nodes -o wide

# NAME         STATUS   ROLES                  AGE     VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION           CONTAINER-RUNTIME
# k8s-master   Ready    control-plane,master   66m     v1.22.1   192.168.31.58    <none>        CentOS Linux 7 (Core)   3.10.0-1160.el7.x86_64   docker://20.10.8
# k8s-worker   Ready    <none>                 6m11s   v1.22.1   192.168.31.232   <none>        CentOS Linux 7 (Core)   3.10.0-1160.el7.x86_64   docker://20.10.8

kubectl patch node k8s-worker -p '{"spec":{"podCIDR":"172.18.1.0/24"}}' # k get po -A |grep kube-flannel

## 为Worker节点设置角色(Master)
kubectl label node k8s-worker node-role.kubernetes.io/worker=worker # kubectl get nodes -o wide


# 部署面板Dashboard（Master）





# # 部署面板Dashboard（Master）
# cd /opt/kubernetes/manifests

# cat dashboard.yaml |grep image # 查看所需镜像
# docker images |grep ydy # 查看拥有的镜像

# vi dashboard.yaml # Directory => DirectoryOrCreate

# k apply -f dashboard.yaml # 部署 watch kubectl get po -n dashboard-cn


# ## 配置面板
# cd /opt/kubernetes/manifests
# curl -L https://downloads.portainer.io/portainer-agent-ce211-k8s-nodeport.yaml -o portainer-agent-k8s.yaml

# cat portainer-agent-k8s.yaml |grep image # 查看需要的镜像

# ### 拉取镜像
# docker pull docker.chenby.cn/portainer/agent:2.11.1

# vi portainer-agent-k8s.yaml 
# # image 改为：image: docker.chenby.cn/portainer/agent:2.11.1
# # imagePullPolicy 改为 IfNotPresent

# kubectl apply -f portainer-agent-k8s.yaml # 部署proxy

# k get svc -n portainer # 获取 portainer-agent IP: 10.99.248.203

# # NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
# # portainer-agent            NodePort    10.99.248.203   <none>        9001:30778/TCP   2m38s
# # portainer-agent-headless   ClusterIP   None            <none>        <none>           2m38s
