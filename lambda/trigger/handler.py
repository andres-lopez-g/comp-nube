"""parcial_ajlg_trigger — S3 (originales) -> ecs:RunTask (Fargate).

Evento: s3:ObjectCreated:* del bucket parcial-ajlg-originales-*.
Acción: lanza la task definition parcial_ajlg_thumb_task pasándole
la ruta de la imagen POR VARIABLE DE ENTORNO (SOURCE_BUCKET,
SOURCE_KEY, DEST_BUCKET, IMAGE_URI), como exige el enunciado.

Env vars de configuración (las pone CloudFormation):
  PARCIAL_AJLG_CLUSTER, PARCIAL_AJLG_TASKDEF, PARCIAL_AJLG_DEST_BUCKET,
  PARCIAL_AJLG_SUBNETS (csv), PARCIAL_AJLG_SG, PARCIAL_AJLG_CONTAINER
"""
import json
import logging
import os
import urllib.parse

import boto3

log = logging.getLogger()
log.setLevel(logging.INFO)

ecs = boto3.client("ecs")


def _record_to_env(record):
    s3 = record.get("s3", {})
    src_bucket = s3.get("bucket", {}).get("name", "")
    src_key = urllib.parse.unquote_plus(s3.get("object", {}).get("key", ""))
    dest_bucket = os.environ["PARCIAL_AJLG_DEST_BUCKET"]
    return src_bucket, src_key, [
        {"name": "SOURCE_BUCKET", "value": src_bucket},
        {"name": "SOURCE_KEY", "value": src_key},
        {"name": "DEST_BUCKET", "value": dest_bucket},
        {"name": "IMAGE_URI", "value": f"s3://{src_bucket}/{src_key}"},
        {"name": "THUMB_SIZE", "value": os.environ.get("THUMB_SIZE", "200")},
        {"name": "DEST_PREFIX", "value": os.environ.get("DEST_PREFIX", "thumbs/")},
    ]


def handler(event, context):
    cluster = os.environ["PARCIAL_AJLG_CLUSTER"]
    taskdef = os.environ["PARCIAL_AJLG_TASKDEF"]
    container = os.environ.get("PARCIAL_AJLG_CONTAINER", "parcial_ajlg_processor")
    subnets = [s.strip() for s in os.environ["PARCIAL_AJLG_SUBNETS"].split(",") if s.strip()]
    sg = os.environ.get("PARCIAL_AJLG_SG", "").strip()

    launched = []
    for record in event.get("Records", []):
        try:
            src_bucket, src_key, env = _record_to_env(record)
        except KeyError as e:
            log.error("config incompleta: %s", e)
            continue
        if not src_bucket or not src_key:
            log.warning("record sin bucket/key, se ignora")
            continue
        net = {"awsvpcConfiguration": {
            "subnets": subnets, "assignPublicIp": "ENABLED"}}
        if sg:
            net["awsvpcConfiguration"]["securityGroups"] = [sg]
        resp = ecs.run_task(
            cluster=cluster, taskDefinition=taskdef, launchType="FARGATE",
            count=1, networkConfiguration=net,
            overrides={"containerOverrides": [
                {"name": container, "environment": env}]},
        )
        tasks = resp.get("tasks", [])
        failures = resp.get("failures", [])
        log.info("RunTask %s/%s tasks=%d failures=%s",
                 src_bucket, src_key, len(tasks), failures)
        launched.append({"key": src_key,
                         "taskArn": tasks[0]["taskArn"] if tasks else None,
                         "failures": failures})
    return {"statusCode": 200, "body": json.dumps({"launched": launched})}
