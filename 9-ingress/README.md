# Ingress

Ingress 为外部访问集群提供了一个 **统一** 入口，避免了对外暴露集群端口；

功能类似 Nginx，可以根据域名、路径把请求转发到不同的 Service；

同时，可以配置 https；



**跟 LoadBalancer 有什么区别？**
LoadBalancer 需要对外暴露端口，不安全；

无法根据域名、路径转发流量到不同 Service，多个 Service 则需要开多个 LoadBalancer；

功能单一，无法配置 https；

![2.png](https://sjwx.easydoc.xyz/46901064/files/kwhd6dc8.png)



### 使用

要使用 Ingress，需要一个负载均衡器 + Ingress Controller

如果是裸机（bare metal) 搭建的集群，你需要自己安装一个负载均衡插件，可以安装 [METALLB](https://metallb.universe.tf/)

如果是云服务商，会自动给你配置，否则你的外部 IP 会是 “pending” 状态，无法使用。

文档：[Ingress](https://kubernetes.io/zh/docs/concepts/services-networking/ingress/)

Minikube 中部署 Ingress Controller：[nginx](https://kubernetes.io/zh/docs/tasks/access-application-cluster/ingress-minikube/)

Helm 安装： [Nginx](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-example
spec:
  ingressClassName: nginx
  rules:
  - host: tools.fun
    http:
      paths:
      - path: /easydoc
        pathType: Prefix
        backend:
          service:
            name: service1
            port:
              number: 4200
      - path: /svnbucket
        pathType: Prefix
        backend:
          service:
            name: service2
            port:
              number: 8080
```

