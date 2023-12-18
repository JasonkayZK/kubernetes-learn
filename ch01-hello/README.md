# Deploy Hello-world

Deploy hello-world application.

## Build & push image

```shell
docker build -t jasonkay/java-deploy-app:v1.0.0 .

docker push jasonkay/java-deploy-app:v1.0.0
```

## Deploy on k8s

```shell
kubectl apply -f deploy/deployment.yaml
```

## Test

```shell
# Curl node port
curl <k8s-node-ip>:32080
```
