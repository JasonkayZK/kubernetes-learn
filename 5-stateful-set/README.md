# **StatefulSet**

doc:

- https://k8s.easydoc.net/docs/dRiQjyTY/28366845/6GiNOzyZ/mJvk9q5z



### 什么是 StatefulSet

StatefulSet 是用来管理有状态的应用，例如数据库。

前面我们部署的应用，都是不需要存储数据，不需要记住状态的，可以随意扩充副本，每个副本都是一样的，可替代的。

而像数据库、Redis 这类有状态的，则不能随意扩充副本。

**StatefulSet 会固定每个 Pod 的名字!**



### 部署 StatefulSet 类型的 Mongodb

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: mongodb
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
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb
spec:
  selector:
    app: mongodb
  type: ClusterIP
  # HeadLess
  clusterIP: None
  ports:
    - port: 27017
      targetPort: 27017
```



### StatefulSet 特性

-   Service 的 `CLUSTER-IP` 是空的，Pod 名字也是固定的。
-   Pod 创建和销毁是有序的，创建是顺序的，销毁是逆序的。
-   Pod 重建不会改变名字，除了IP，所以不要用IP直连

```
✗ k get pods
NAME                        READY   STATUS    RESTARTS   AGE
test-k8s-86988dc99c-tvkkw   1/1     Running   0          115m
test-k8s-86988dc99c-rlp8m   1/1     Running   0          115m
mongodb-0                   1/1     Running   0          4m2s
mongodb-1                   1/1     Running   0          3m16s
mongodb-2                   1/1     Running   0          2m27s

✗ k get svc 
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.43.0.1      <none>        443/TCP          125m
test-k8s     NodePort    10.43.155.21   <none>        8080:31000/TCP   45m
mongodb      ClusterIP   None           <none>        27017/TCP        4m10s
```

Endpoints 会多一个 hostname：

```yaml
✗ k get endpoints mongodb -o yaml

apiVersion: v1
kind: Endpoints
metadata:
  annotations:
    endpoints.kubernetes.io/last-change-trigger-time: "2023-07-03T04:09:44Z"
  creationTimestamp: "2023-07-03T04:07:22Z"
  labels:
    service.kubernetes.io/headless: ""
  name: mongodb
  namespace: default
  resourceVersion: "6516"
  uid: b96cead9-0e3a-4f5d-b58f-763fbeffc7df
subsets:
- addresses:
  - hostname: mongodb-0
    ip: 10.42.0.17
    nodeName: k3d-my-k3s-agent-0
    targetRef:
      kind: Pod
      name: mongodb-0
      namespace: default
      uid: b38de486-a70a-475c-bcf7-4bf6278f7408
  - hostname: mongodb-1
    ip: 10.42.1.18
    nodeName: k3d-my-k3s-agent-1
    targetRef:
      kind: Pod
      name: mongodb-1
      namespace: default
      uid: ffe34e7b-2e84-4404-b61d-8ded8b8300ca
  - hostname: mongodb-2
    ip: 10.42.2.14
    nodeName: k3d-my-k3s-server-0
    targetRef:
      kind: Pod
      name: mongodb-2
      namespace: default
      uid: 1b0d2ada-dce7-4f1e-b993-0574ca1d1880
  ports:
  - port: 27017
    protocol: TCP
```

访问时：

-   如果直接使用 Service 名字连接，会随机转发请求！
-   要连接指定 Pod，可以这样：`pod-name.service-name`

运行一个临时 Pod 连接数据测试：

```
kubectl run mongodb-client --rm --tty -i --restart='Never' --image docker.io/bitnami/mongodb:4.4.10-debian-10-r20 --command -- bash
```

登陆一个数据库：

```
 mongo --host mongodb-0.mongodb
```

创建一个用户并查看：

```
> db.users.save({'_id': '123', 'name': 'abc'})

WriteResult({ "nMatched" : 0, "nUpserted" : 1, "nModified" : 0, "_id" : "123" })

> db.users.find()

{ "_id" : "123", "name" : "abc" }
```

登陆另一个数据库：

```
mongo --host mongodb-1.mongodb
```

查看：

```
> show dbs

admin   0.000GB
config  0.000GB
local   0.000GB
```

发现并没有刚才创建的数据，因为这是另一个数据库；

在这个数据库再创建一条数据：

```
> db.users.save({'_id': '456', 'name': 'def'})
WriteResult({ "nMatched" : 0, "nUpserted" : 1, "nModified" : 0, "_id" : "456" })

> db.users.find()
{ "_id" : "456", "name" : "def" }
```

再去第三个数据库创建：

```
mongo --host mongodb-2.mongodb

db.users.save({'_id': '789', 'name': 'hij'})
```



### Web 应用连接 Mongodb

在集群内部，我们可以通过服务名字访问到不同的服务；

指定连接第一个：`mongodb-0.mongodb`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  # 部署名字
  name: test-k8s
spec:
  replicas: 2
  # 用来查找关联的 Pod，所有标签都匹配才行
  selector:
    matchLabels:
      app: test-k8s
  # 定义 Pod 相关数据
  template:
    metadata:
      labels:
        app: test-k8s
    spec:
      # 定义容器，可以多个
      containers:
        - name: test-k8s # 容器名字
          image: ccr.ccs.tencentyun.com/k8s-tutorial/test-k8s:v3-mongo # 镜像
          volumeMounts:
            - mountPath: /.dockerenv
              name: env-docker
      # 等待 mongodb 起来后才启动
      initContainers:
        - name: wait-mongo
          image: busybox:1.28
          command: ['sh', '-c', "until nslookup mongodb; do echo waiting for mongo; sleep 2; done"]
      volumes:
        - name: env-docker
          hostPath:
            path: /Users/zk/workspace/kubernetes-learn/5-stateful-set/.dockerenv
---
apiVersion: v1
kind: Service
metadata:
  name: test-k8s
spec:
  selector:
    app: test-k8s
  # 默认 ClusterIp 集群内可访问，NodePort 节点可访问，LoadBalancer 负载均衡模式（需要负载均衡器才可用）
  type: NodePort
  ports:
    - nodePort: 31000   # 节点端口，范围固定 30000 ~ 32767
      port: 8080        # 本 Service 的端口
      targetPort: 8080  # 容器端口
```

>   **镜像中没有 .dockerenv 文件，需要手动挂载；**
>
>   **否则连不上mongodb**

```
✗ k get all

NAME                            READY   STATUS    RESTARTS   AGE
pod/test-k8s-86988dc99c-tvkkw   1/1     Running   0          129m
pod/test-k8s-86988dc99c-rlp8m   1/1     Running   0          129m
pod/mongodb-0                   1/1     Running   0          18m
pod/mongodb-1                   1/1     Running   0          17m
pod/mongodb-2                   1/1     Running   0          16m

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/kubernetes   ClusterIP   10.43.0.1      <none>        443/TCP          139m
service/test-k8s     NodePort    10.43.155.21   <none>        8080:31000/TCP   60m
service/mongodb      ClusterIP   None           <none>        27017/TCP        18m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/test-k8s   2/2     2            2           129m

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/test-k8s-86988dc99c   2         2         2       129m

NAME                       READY   AGE
statefulset.apps/mongodb   3/3     18m
```

创建用户：

```shell
curl --location 'localhost:8888/regist' \
--header 'Content-Type: application/json' \
--data '{
    "username": "abc",
    "password": "21"
}'
```

返回：

```json
{"code":0,"msg":"success"}
```

登陆：

```shell
curl --location 'localhost:8888/login' \
--header 'Content-Type: application/json' \
--data '{
    "username": "abc",
    "password": "21"
}'
```

返回：

```json
{"_id":"abc","password":"21"}
```

查看数据库：

```
> use testdb
switched to db testdb

> show tables
users

> db.users.find()
{ "_id" : "abc", "password" : "21" }
{ "_id" : "def", "password" : "21" }
```



### 问题

**pod 重建后，数据库的内容丢失了**

下节，我们讲解如何解决这个问题。

