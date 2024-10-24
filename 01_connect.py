from kubernetes.client import api_client
from kubernetes.client.api import core_v1_api
from kubernetes import client, config

K8S_URL: str = 'https://10.147.17.30:6443'
K8S_TOKEN: str = '<your-token>'

if __name__ == '__main__':
    configuration = client.Configuration()
    configuration.host = K8S_URL
    configuration.verify_ssl = False
    configuration.api_key = {"authorization": "Bearer " + K8S_TOKEN}
    client1 = api_client.ApiClient(configuration=configuration)
    cli = core_v1_api.CoreV1Api(client1)

    # 获取所有 Namespace
    namespace_list = []
    for ns in cli.list_namespace().items:
        # print(ns.metadata.name)
        namespace_list.append(ns.metadata.name)
    print('Namespace list:\n', namespace_list, '\n')
    