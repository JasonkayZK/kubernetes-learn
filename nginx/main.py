import kubernetes
import yaml

kubernetes.config.kube_config.load_kube_config(config_file="/root/.kube/config")
cli = kubernetes.client.CoreV1Api()

# 第一题
namelist = cli.list_service_for_all_namespaces()
for i in namelist.items:
    if i.metadata.name == "nginx-svc":
        print(f"{i}")
        cli.delete_namespaced_service("nginx-svc", i.metadata.namespace)
        break

print(f"\n Step 1: finished\n")

# 第二题
print(f"\n Step 2: Start!\n")

with open("nginx-svc.yaml", "r") as file:
    service_yaml = yaml.safe_load(file)
    cli.create_namespaced_service(body=service_yaml, namespace="zk")

print(f"\n Step 2: finished\n")

# 第三题
print(f"\n Step 3: Start!\n")

namelist = cli.list_service_for_all_namespaces()
for i in namelist.items:
    if i.metadata.name == "nginx-svc":
        with open("service_api_dev.json", "w") as jsonfile:
            jsonfile.write(str(i.to_dict()))
        break

print(f"\n Step 3: finished\n")

# 第四题
print(f"\n Step 4: Start!\n")

with open("nginx-svc-update.yaml", "r") as file:
    service_yaml_update = yaml.safe_load(file)
    cli.patch_namespaced_service(body=service_yaml_update, namespace="zk", name="nginx-svc")

print(f"\n Step 4: finished\n")

# 第五题
namelist = cli.list_service_for_all_namespaces()
for i in namelist.items:
    if i.metadata.name == "nginx-svc":
        print('\n\n\n Step 5')
        with open("service_api_dev.json", "a+") as jsonfile:
            jsonfile.write(str(i.to_dict()))
        break

# END
