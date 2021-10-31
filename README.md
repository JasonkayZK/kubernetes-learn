# **Project Deploy Demo**

A demo to show how to deploy project to k8s.

## Project Info

Project is simple:

- `:8080/`: show `<h1>Hello World</h1>`
- `:8080/health_check`: show `<h1>Health check</h1>`

<br/>

## How to use

### 1.Test Your Application.

Run app local:

```shell
go run main.go
```

Open browser to: 
- [localhost:8080/](localhost:8080/)
- [localhost:8080/health_check](localhost:8080/health_check)

It’s ok to see:

![demo1](https://cdn.jsdelivr.net/gh/jasonkayzk/kubernetes-learn@go-hello-deploy-demo/images/demo1.png)

And `Health check`;

<br/>

### 2.Build your onw image

Write `Dockerfile`

```dockerfile
FROM golang:1.17.2-alpine3.14
MAINTAINER jasonkayzk@gmail.com
RUN mkdir /app
COPY . /app
WORKDIR /app
RUN go build -o main .
CMD ["/app/main"]
```

>   You can change `FROM <image>` arbitrarily.

Build Image:

```shell
docker build -t jasonkay/go-hello-app:v0.0.1 .
```

>   You can change `image-name` arbitrarily.

Push Image:

```bash
docker push jasonkay/go-hello-app:v0.0.1
```



>   **Local Check(Optional)**
>
>   Use `docker run -d -p 8080:8080 --rm --name go-hello-app-container jasonkay/go-hello-app:v0.0.1` to test in docker container.

<br/>

### 3.Deploy in K8S

Create file `deployment.yaml`:

deploy/deployment.yaml

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-hello-app
  namespace: my-workspace # 声明工作空间，默认为default
spec:
  replicas: 2
  selector:
    matchLabels:
      name: go-hello-app
  template:
    metadata:
      labels:
        name: go-hello-app
    spec:
      containers:
        - name: go-hello-container
          image: jasonkay/go-hello-app:v0.0.1
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080 # containerPort是声明容器内部的port

---
apiVersion: v1
kind: Service
metadata:
  name: go-hello-app-service
  namespace: my-workspace # 声明工作空间，默认为default
spec:
  type: NodePort
  ports:
    - name: http
      port: 18080 # Service暴露在cluster-ip上的端口，通过<cluster-ip>:port访问服务,通过此端口集群内的服务可以相互访问
      targetPort: 8080 # Pod的外部访问端口，port和nodePort的数据通过这个端口进入到Pod内部，Pod里面的containers的端口映射到这个端口，提供服务
      nodePort: 31080 # Node节点的端口，<nodeIP>:nodePort 是提供给集群外部客户访问service的入口
  selector:
    name: go-hello-app
```

>   **Your may need to change some configs:**
>
>   -   **metadata.namespace;**
>   -   **spec.spec.containers.image;**

then deploy to your k8s cluster:

```shell
kubectl create -f deploy/deployment.yaml
```

<br/>

### 4.Check Deployment

First, use command to check:

```shell
kubectl get po -n my-workspace
 
NAME                            READY   STATUS    RESTARTS   AGE
go-hello-app-555c69b994-zt9zf   2/2     Running   0          54m
go-hello-app-555c69b994-zwdb7   2/2     Running   0          54m
```

Second, use dashboard to check:

![demo2](https://cdn.jsdelivr.net/gh/jasonkayzk/kubernetes-learn@go-hello-deploy-demo/images/demo2.png)

Finally, Visit NodePort to check:

-   [http://k8s-node-ip:31080/](http://localhost:31080/)

And you will see just as the same as:

![demo1](https://cdn.jsdelivr.net/gh/jasonkayzk/kubernetes-learn@go-hello-deploy-demo/images/demo1.png)

<br/>

### 5.Delete Deployment

Use command below to delete Deployment:

```shell
kubectl delete -f deploy/deployment.yaml
```

<br/>

## Linked Blog

[使用K8S部署最简单的Go应用](https://jasonkayzk.github.io/2021/10/31/使用K8S部署最简单的Go应用/)

