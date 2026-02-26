#!/bin/bash

NAMESPACE="dify-v1"

echo "获取命名空间信息..."
kubectl get namespace $NAMESPACE -o json > /tmp/ns.json

echo "移除finalizers..."
cat /tmp/ns.json | jq '.spec.finalizers = []' > /tmp/ns-nofinalizer.json

echo "应用修改后的命名空间定义..."
kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f /tmp/ns-nofinalizer.json

echo "检查命名空间状态..."
kubectl get namespace $NAMESPACE

echo "如果上述方法不起作用，尝试直接从etcd中删除命名空间..."
echo "注意：以下命令需要在控制平面节点上执行，并且需要访问etcd"
echo "ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key del /registry/namespaces/$NAMESPACE"

echo "脚本执行完成"