import json
import os
import functions_framework
import google.cloud.logging
import logging


@functions_framework.http
def main(_request):
    # https://cloud.google.com/functions/docs/configuring/env-var?hl=ja#runtime_environment_variables_set_automatically
    # Cloud Functions の予約済み環境変数 FUNCTION_TARGET が存在する場合、Cloud logging を使う。
    if os.getenv("FUNCTION_TARGET"):
        cloud_logging_client = google.cloud.logging.Client()
        cloud_logging_client.setup_logging(log_level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.DEBUG)

    additional_params = {"a": 1}

    # extra と json_fields を使うと、jsonPayload 内に additional_params の部分だけ含まれる。
    # ローカル環境では additional_params は表示されない。
    logging.error(msg="msg log", extra={"json_fields": additional_params})

    # ローカル環境でも additional_params は表示される。
    log_message = {"message": "json dumps log"}
    log_message |= additional_params
    logging.error(json.dumps(log_message))

    # severity が必要
    log_message = {"message": "print json dumps log"}
    log_message |= additional_params
    log_message |= {"severity": "error"}
    print(json.dumps(log_message))

    return "ok"
