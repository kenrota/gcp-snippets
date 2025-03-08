import os
import functions_framework
from cloudevents.http.event import CloudEvent
import requests


@functions_framework.cloud_event
def main(_cloud_event: CloudEvent):
    vm_dns_name = os.environ.get("VM_DNS_NAME")
    url = f"http://{vm_dns_name}:8080"
    response = requests.get(url, timeout=5)
    print(f"{response.text=}")
