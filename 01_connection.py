import urllib3

from kubernetes.client import api_client
from kubernetes.client.api import core_v1_api
from kubernetes import client, config


class KubernetesHandler(object):
    __K8S_URL: str = 'https://10.147.17.30:6443'
    __K8S_TOKEN: str = None
    __K8S_CONFIG_FILE: str = "kube-config.yaml"

    def __init__(self):
        pass

    @staticmethod
    def get_token():
        """
        获取token
        :return:
        """
        if not KubernetesHandler.__K8S_TOKEN:
            with open(r'kube-token.txt', 'r') as file:
                KubernetesHandler.__K8S_TOKEN = file.read().strip('\n')
        return KubernetesHandler.__K8S_TOKEN

    @staticmethod
    def get_client_by_token():
        """
        通过Token获取API的Client
        :return:
        """
        configuration = client.Configuration()
        configuration.host = KubernetesHandler.__K8S_URL
        configuration.verify_ssl = False
        configuration.api_key = {"authorization": "Bearer " + KubernetesHandler.get_token()}
        client1 = api_client.ApiClient(configuration=configuration)
        cli = core_v1_api.CoreV1Api(client1)
        return cli

    @staticmethod
    def get_client_by_config():
        """
        通过Config文件获取Client
        :return:
        """
        config.kube_config.load_kube_config(config_file=KubernetesHandler.__K8S_CONFIG_FILE)
        return client.CoreV1Api()


if __name__ == '__main__':
    urllib3.disable_warnings()

    cli = KubernetesHandler.get_client_by_token()
    # cli = KubernetesHandler.get_client_by_config()

    # 获取所有 Namespace
    namespace_list = []
    for ns in cli.list_namespace().items:
        # print(ns.metadata.name)
        namespace_list.append(ns.metadata.name)
    print('Namespace list:\n', namespace_list, '\n')

    # 获取所有 Pod
    pod_list = cli.list_pod_for_all_namespaces(watch=False)
    print("Listing pods with their IPs:\n")
    for i in pod_list.items:
        print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))
    print()

    # 获取所有 Service
    services = cli.list_service_for_all_namespaces(watch=False)
    print('Service list:')
    for i in services.items:
        print("%s \t%s \t%s \t%s \t%s \n" % (
            i.kind, i.metadata.namespace, i.metadata.name, i.spec.cluster_ip, i.spec.ports))
