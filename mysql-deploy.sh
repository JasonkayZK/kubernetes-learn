# Create Secret
kubectl apply -f mysql-secret.yaml
## Check Secret
kubectl get secret mysql-secret -o yaml

# Create ConfigMap
kubectl apply -f mysql-config.yaml

# Create Volume
kubectl apply -f mysql-storage.yaml

# Deploy MySQL
kubectl apply -f mysql-deploy.yaml
