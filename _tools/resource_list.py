import json
import subprocess
import pandas as pd
import argparse
from tabulate import tabulate


def run_command(cmd: str) -> list[dict]:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {result.stderr}")
    return json.loads(result.stdout)


def list_vm_instances(project_id: str) -> list[dict]:
    cmd = f"gcloud compute instances list --project={project_id} --format=json"

    def _to_resource(instance: dict):
        internal_ips = []
        external_ips = []
        for interface in instance.get("networkInterfaces", []):
            internal_ips.append(interface["networkIP"])
            access_configs = interface.get("accessConfigs", [])
            external_ips += list(map(lambda x: x["natIP"], access_configs))

        return {
            "Type": "VM",
            "Name": instance["name"],
            "Endpoint": ", ".join(internal_ips + external_ips),
        }

    return list(map(_to_resource, run_command(cmd)))


def list_cloud_run_services(project_id: str) -> list[dict]:
    cmd = f"gcloud run services list --project={project_id} --format=json"

    def _get_resource_type(service: dict):
        return (
            "Run Functions"
            if service["metadata"]["labels"].get("goog-managed-by") == "cloudfunctions"
            else "Run Services"
        )

    def _to_resource(service: dict):
        return {
            "Type": _get_resource_type(service),
            "Name": service["metadata"]["name"],
            "Endpoint": service["status"]["url"],
        }

    return list(map(_to_resource, run_command(cmd)))


def list_bigtable_instances(project_id: str) -> list[dict]:
    cmd = f"gcloud bigtable instances list --project={project_id} --format=json"

    def _to_resource(instance: dict):
        return {
            "Type": "Bigtable",
            "Name": instance["displayName"],
            "Endpoint": "",
        }

    return list(map(_to_resource, run_command(cmd)))


def list_storage_buckets(project_id: str) -> list[dict]:
    cmd = f"gcloud storage buckets list --project={project_id} --format=json"

    def _to_resource(bucket: dict):
        return {
            "Type": "Storage",
            "Name": bucket["name"],
            "Endpoint": bucket["storage_url"],
        }

    return list(map(_to_resource, run_command(cmd)))


def list_resources(project_id: str) -> list[dict]:
    resources = []
    resources += list_vm_instances(project_id)
    resources += list_cloud_run_services(project_id)
    resources += list_bigtable_instances(project_id)
    resources += list_storage_buckets(project_id)
    return resources


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-id", required=True)
    parser.add_argument("--csv", help="Output CSV file path")
    args = parser.parse_args()
    project_id = args.project_id

    resources = list_resources(project_id)

    if len(resources) > 0:
        df = pd.DataFrame(resources)

        if args.csv:
            df.to_csv(args.csv, index=False)
            print(f"CSV written to: {args.csv}")
        else:
            print(tabulate(df, headers="keys", showindex=False))
    else:
        print("Resource not found.")


if __name__ == "__main__":
    main()
