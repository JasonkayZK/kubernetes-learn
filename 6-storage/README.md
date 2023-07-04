# Storage

doc:

-   https://k8s.easydoc.net/docs/dRiQjyTY/28366845/6GiNOzyZ/Q2gBbjyW



kubernetes 集群不会为你处理数据的存储，我们可以为数据库挂载一个磁盘来确保数据的安全。

你可以选择云存储、本地磁盘、NFS。

-   本地磁盘：可以挂载某个节点上的目录，但是这需要限定 pod 在这个节点上运行；
-   云存储：不限定节点，不受集群影响，安全稳定；需要云服务商提供，裸机集群是没有的；
-   NFS：不限定节点，不受集群影响；



### hostPath 挂载示例

把节点上的一个目录挂载到 Pod，但是已经不推荐使用了：

-   https://kubernetes.io/zh/docs/concepts/storage/volumes/#hostpath

配置方式简单，需要**手动指定 Pod 跑在某个固定的节点。**

**仅供单节点测试使用；不适用于多节点集群。**

minikube 提供了 hostPath 存储：

-   https://minikube.sigs.k8s.io/docs/handbook/persistent_volumes/

例如：

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  serviceName: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongo
          image: mongo:4.4
          # IfNotPresent 仅本地没有镜像时才远程拉，Always 永远都是从远程拉，Never 永远只用本地镜像，本地没有则报错
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - mountPath: /data/db # 容器里面的挂载路径
              name: mongo-data    # 卷名字，必须跟下面定义的名字一致
      volumes:
        - name: mongo-data              # 卷名字
          hostPath:
            path: /data/mongo-data      # 节点上的路径
            type: DirectoryOrCreate     # 指向一个目录，不存在时自动创建
```



### 更高级的抽象

![持久卷](https://sjwx.easydoc.xyz/46901064/files/kwrmidne.png)

#### torage Class (SC)

将存储卷划分为不同的种类，例如：SSD，普通磁盘，本地磁盘，按需使用：

-   https://kubernetes.io/zh/docs/concepts/storage/storage-classes/

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: slow
provisioner: kubernetes.io/aws-ebs
parameters:
  type: io1
  iopsPerGB: "10"
  fsType: ext4
```



#### Persistent Volume (PV)

描述卷的具体信息，例如磁盘大小，[访问模式](https://kubernetes.io/zh/docs/concepts/storage/persistent-volumes/#access-modes)：

[文档](https://kubernetes.io/zh/docs/concepts/storage/persistent-volumes/)，[类型](https://kubernetes.io/zh/docs/concepts/storage/persistent-volumes/#types-of-persistent-volumes)，[Local 示例](https://kubernetes.io/zh/docs/concepts/storage/volumes/#local)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodata
spec:
  capacity:
    storage: 2Gi
  volumeMode: Filesystem  # Filesystem（文件系统） Block（块）
  accessModes:
    - ReadWriteOnce       # 卷可以被一个节点以读写方式挂载
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /root/data
  nodeAffinity:
    required:
      # 通过 hostname 限定在某个节点创建存储卷
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - node2
```



#### Persistent Volume Claim (PVC)

对存储需求的一个申明，可以理解为一个申请单，系统根据这个申请单去找一个合适的 PV
还可以根据 PVC 自动创建 PV。

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodata
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: "local-storage"
  resources:
    requests:
      storage: 2Gi
```



#### 为什么要这么多层抽象

-   更好的分工，运维人员负责提供好存储，开发人员不需要关注磁盘细节，只需要写一个申请单。
-   方便云服务商提供不同类型的，配置细节不需要开发者关注，只需要一个申请单。
-   [动态创建](https://kubernetes.io/zh/docs/concepts/storage/dynamic-provisioning/)，开发人员写好申请单后，供应商可以根据需求自动创建所需存储卷。



### 本地磁盘示例

不支持动态创建，需要提前创建好

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  serviceName: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongo
          image: mongo:4.4
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - mountPath: /data/db
              name: mongo-data
      volumes:
        - name: mongo-data
          persistentVolumeClaim:
            claimName: mongodata-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: mongodb
spec:
  clusterIP: None
  ports:
    - port: 27017
      protocol: TCP
      targetPort: 27017
  selector:
    app: mongodb
  type: ClusterIP

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodata-pv
  labels:
    type: local
spec:
  capacity:
    storage: 2Gi
  volumeMode: Filesystem  # Filesystem（文件系统） Block（块）
  accessModes:
    - ReadWriteOnce       # 卷可以被一个节点以读写方式挂载
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /data
  nodeAffinity:
    required:
      # 通过 hostname 限定在某个节点创建存储卷
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - "k3d-my-k3s-server-0"

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodata-pvc
spec:
  accessModes: [ "ReadWriteOnce" ]
  storageClassName: "local-storage"
  resources:
    requests:
      storage: 2Gi
```



### 问题

当前数据库的连接地址是写死在代码里的，另外还有数据库的密码需要配置。

下节，我们讲解如何解决。

