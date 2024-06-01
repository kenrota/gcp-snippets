import functions_framework
from cloudevents.http.event import CloudEvent


@functions_framework.cloud_event
def main(cloud_event: CloudEvent) -> None:
    print(f"{cloud_event=}")
