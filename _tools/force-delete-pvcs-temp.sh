#!/bin/bash

NAMESPACE="zk"

# 获取所有处于Terminating状态的PVC
PVCS=(
  "test-pvc"
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
