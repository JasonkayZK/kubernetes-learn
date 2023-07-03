# Service

doc:

- https://k8s.easydoc.net/docs/dRiQjyTY/28366845/6GiNOzyZ/C0fakgwO



### 特性

-   Service 通过 label 关联对应的 Pod
-   Servcie 生命周期不跟 Pod 绑定，不会因为 Pod 重创改变 IP
-   提供了负载均衡功能，自动转发流量到不同 Pod
-   可对集群外部提供访问端口
-   集群内部可通过服务名字访问



### 创建 Service（ClusterIP）

创建 一个 Service，通过标签`test-k8s`跟对应的 Pod 关联上`service.yaml`：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-k8s
spec:
  selector:
    app: test-k8s
  type: ClusterIP
  ports:
    - port: 8080        # 本 Service 的端口
      targetPort: 8080  # 容器端口
```

应用配置 `kubectl apply -f service.yaml`；

看服务 `kubectl get svc`：

```
k get svc

NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.43.0.1      <none>        443/TCP    79m
test-k8s     ClusterIP   10.43.155.21   <none>        8080/TCP   14s
```

查看服务详情 `kubectl describe svc test-k8s`；

可以发现 Endpoints 是各个 Pod 的 IP，也就是他会把流量转发到这些节点：

```
k describe svc test-k8s
 
Name:              test-k8s
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          app=test-k8s
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.43.155.21
IPs:               10.43.155.21
Port:              <unset>  8080/TCP
TargetPort:        8080/TCP
Endpoints:         10.42.0.16:8080,10.42.1.17:8080
Session Affinity:  None
Events:            <none>
```

**服务的默认类型是`ClusterIP`，只能在集群内部访问，我们可以进入到 Pod 里面访问：**

```shell
kubectl exec -it pod-name -- bash

curl http://test-k8s:8080
```

**如果要在集群外部访问，可以通过端口转发实现（只适合临时测试用）：**

-   `kubectl port-forward service/test-k8s 8888:8080`

>   如果你用 minikube，也可以这样`minikube service test-k8s`



### 对外暴露服务

上面我们是通过端口转发的方式可以在外面访问到集群里的服务，如果想要直接把集群服务暴露出来，我们可以使用`NodePort` 和 `Loadbalancer` 类型的 Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-k8s
spec:
  selector:
    app: test-k8s
  # 默认 ClusterIP 集群内可访问，NodePort 节点可访问，LoadBalancer 负载均衡模式（需要负载均衡器才可用）
  type: NodePort
  ports:
    - port: 8080        # 本 Service 的端口
      targetPort: 8080  # 容器端口
      nodePort: 31000   # 节点端口，范围固定 30000 ~ 32767
```

应用配置 `kubectl apply -f service.yaml`；

在节点上，我们可以 `curl http://<node-ip>:31000/hello/abc` 访问到应用，并且是有负载均衡的，网页的信息可以看到被转发到了不同的 Pod：

```
index page 

IP lo10.42.0.16, hostname: test-k8s-86988dc99c-rlp8m
```

>   如果你是用 minikube，因为是模拟集群，你的电脑并不是节点，节点是 minikube 模拟出来的，所以你并不能直接在电脑上访问到服务；
>
>   如果是mac上用 colima 创建的，需要先 `colima ssh` 进入虚拟机，然后再访问；

`Loadbalancer` 也可以对外提供服务，这需要一个负载均衡器的支持，因为它需要生成一个新的 IP 对外服务，否则状态就一直是 pendding，这个很少用了，后面我们会讲更高端的 Ingress 来代替它；



### 多端口

多端口时必须配置 name：

-   [文档](https://kubernetes.io/zh/docs/concepts/services-networking/service/#multi-port-services)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-k8s
spec:
  selector:
    app: test-k8s
  type: NodePort
  ports:
    - port: 8080        # 本 Service 的端口
      name: test-k8s    # 必须配置
      targetPort: 8080  # 容器端口
      nodePort: 31000   # 节点端口，范围固定 30000 ~ 32767
    - port: 8090
      name: test-other
      targetPort: 8090
      nodePort: 32000
```



### 总结

##### ClusterIP

默认的，仅在集群内可用

##### NodePort

暴露端口到节点，提供了集群外部访问的入口

**端口范围固定 30000 ~ 32767**

##### LoadBalancer

**需要负载均衡器（通常都需要云服务商提供，裸机可以安装 [METALLB](https://metallb.universe.tf/) 测试）**

会额外生成一个 IP 对外服务

K8S 支持的负载均衡器：[负载均衡器](https://kubernetes.io/zh/docs/concepts/services-networking/service/#internal-load-balancer)

##### Headless

适合数据库

clusterIp 设置为 None 就变成 Headless 了，不会再分配 IP，后面会再讲到具体用法

-   [官网文档](https://kubernetes.io/zh/docs/concepts/services-networking/service/#headless-services)

