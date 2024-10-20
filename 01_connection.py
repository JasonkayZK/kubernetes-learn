import urllib3
from kubernetes.client import api_client
from kubernetes.client.api import core_v1_api
from kubernetes import client


class KubernetesHandler(object):
    def __init__(self):
        self.k8s_url = 'https://10.147.17.30:6443'

    @staticmethod
    def get_token():
        """
        获取token
        :return:
        """
        with open(r'kube-token.txt', 'r') as file:
            token = file.read().strip('\n')
            return token

    def get_api(self):
        """
        获取API的CoreV1Api版本对象
        :return:
        """
        configuration = client.Configuration()
        configuration.host = self.k8s_url
        configuration.verify_ssl = False
        configuration.api_key = {"authorization": "Bearer " + self.get_token()}
        client1 = api_client.ApiClient(configuration=configuration)
        api = core_v1_api.CoreV1Api(client1)
        return api

    def get_namespace_list(self):
        """
        获取命名空间列表
        :return:
        """
        api = self.get_api()
        namespaces = []
        for ns in api.list_namespace().items:
            # print(ns.metadata.name)
            namespaces.append(ns.metadata.name)
        return namespaces

    def get_pod_list(self):
        api = self.get_api()
        return api.list_pod_for_all_namespaces(watch=False)

    def get_service_list(self):
        api = self.get_api()
        return api.list_service_for_all_namespaces(watch=False)


if __name__ == '__main__':
    urllib3.disable_warnings()

    namespace_list = KubernetesHandler().get_namespace_list()
    print('Namespace list:\n', namespace_list, '\n')

    pod_list = KubernetesHandler().get_pod_list()
    print("Listing pods with their IPs:\n")
    for i in pod_list.items:
        print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))
    print()

    services = KubernetesHandler().get_service_list()
    print('Service list:')
    for i in services.items:
        print("%s \t%s \t%s \t%s \t%s \n" % (
            i.kind, i.metadata.namespace, i.metadata.name, i.spec.cluster_ip, i.spec.ports))
