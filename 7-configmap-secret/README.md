# ConfigMap & Secret

doc:

-   https://k8s.easydoc.net/docs/dRiQjyTY/28366845/6GiNOzyZ/YJf8LMtE



### ConfigMap

数据库连接地址，这种可能根据部署环境变化的，我们不应该写死在代码里。

Kubernetes 为我们提供了 ConfigMap，可以方便的配置一些变量；

文档：

-   https://kubernetes.io/zh/docs/concepts/configuration/configmap/

configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-config
data:
  mongoHost: mongodb-0.mongodb
```

```bash
# 应用
kubectl apply -f configmap.yaml

# 查看
kubectl get configmap mongo-config -o yaml

apiVersion: v1
data:
  mongoHost: mongodb-0.mongodb
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"mongoHost":"mongodb-0.mongodb"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"mongo-config","namespace":"default"}}
  creationTimestamp: "2023-07-04T10:20:08Z"
  name: mongo-config
  namespace: default
  resourceVersion: "14261"
  uid: 7b43b268-51e2-4e2a-91ef-3567e665bb92
```



### Secret

一些重要数据，例如密码、TOKEN，我们可以放到 secret 中：

[文档](https://kubernetes.io/zh/docs/concepts/configuration/secret/)，[配置证书](https://kubernetes.io/zh/docs/concepts/configuration/secret/#tls-secret)

>   注意，数据要进行 Base64 编码；
>
>   -   [Base64 工具](https://tools.fun/base64.html)

secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
# Opaque 用户定义的任意数据，更多类型介绍 https://kubernetes.io/zh/docs/concepts/configuration/secret/#secret-types
type: Opaque
data:
  # 数据要 base64。https://tools.fun/base64.html
  mongo-username: bW9uZ291c2Vy
  mongo-password: bW9uZ29wYXNz
```

```bash
# 应用
kubectl apply -f secret.yaml

# 查看
kubectl get secret mongo-secret -o yaml

apiVersion: v1
data:
  mongo-password: bW9uZ29wYXNz
  mongo-username: bW9uZ291c2Vy
kind: Secret
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"mongo-password":"bW9uZ29wYXNz","mongo-username":"bW9uZ291c2Vy"},"kind":"Secret","metadata":{"annotations":{},"name":"mongo-secret","namespace":"default"},"type":"Opaque"}
  creationTimestamp: "2023-07-04T10:23:44Z"
  name: mongo-secret
  namespace: default
  resourceVersion: "14371"
  uid: 46de2593-a8af-422f-8325-7f394350dbe3
type: Opaque
```



### 使用方法

##### 作为环境变量使用

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mongodb
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
          env:
          - name: MONGO_INITDB_ROOT_USERNAME
            valueFrom:
              secretKeyRef:
                name: mongo-secret
                key: mongo-username
          - name: MONGO_INITDB_ROOT_PASSWORD
            valueFrom:
              secretKeyRef:
                name: mongo-secret
                key: mongo-password
          # Secret 的所有数据定义为容器的环境变量，Secret 中的键名称为 Pod 中的环境变量名称
          # envFrom:
          # - secretRef:
          #     name: mongo-secret
```



##### 挂载为文件（更适合证书文件）

挂载后，会在容器中对应路径生成文件，一个 key 一个文件，内容就是 value，[文档](https://kubernetes.io/zh/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: mypod
      image: redis
      volumeMounts:
        - name: mongo
          mountPath: "/etc/foo"
          readOnly: true
  volumes:
    - name: mongo
      secret:
        secretName: mongo-secret
```

