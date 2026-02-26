#!/bin/bash

NAMESPACE="dify-v1"

# 获取所有处于Terminating状态的PVC
PVCS=(
  "demo"
  "api-pvc"
  "db-pvc"
  "nginx-claim6"
  "nginx-claim7"
  "nginx-claim8"
  "plugin-daemon-pvc"
  "redis-pvc"
  "weaviate-pvc"
)

echo "开始强制删除PVC..."

# 移除PVC的finalizers
for PVC in "${PVCS[@]}"; do
  echo "处理 $PVC..."
  
  # 获取PVC的JSON定义
  kubectl get pvc $PVC -n $NAMESPACE -o json > /tmp/pvc-$PVC.json
  
  # 移除finalizers
  cat /tmp/pvc-$PVC.json | jq '.metadata.finalizers = null' > /tmp/pvc-$PVC-nofinalizer.json
  
  # 应用修改后的定义
  kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/persistentvolumeclaims/$PVC/status" -f /tmp/pvc-$PVC-nofinalizer.json
  
  # 强制删除PVC
  kubectl delete pvc $PVC -n $NAMESPACE --force --grace-period=0
  
  echo "$PVC 处理完成"
done

echo "所有PVC处理完成"

# 删除configmap
echo "删除configmap/istio-ca-root-cert..."
kubectl delete configmap istio-ca-root-cert -n $NAMESPACE --force --grace-period=0

# 最后应用无finalizer的命名空间定义
echo "应用无finalizer的命名空间定义..."
kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f /root/workspace/k8s/ns-remove-finalizer.yaml

echo "脚本执行完成，请检查命名空间状态"