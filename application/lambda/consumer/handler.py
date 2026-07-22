import json
import logging
import os

import boto3
from common_logging import log_event

logger = logging.getLogger()
logger.setLevel(logging.INFO)
stepfunctions = boto3.client("stepfunctions")


def handler(event: dict, _context: object) -> dict:
    failures = []
    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            stepfunctions.start_execution(
                stateMachineArn=os.environ["STATE_MACHINE_ARN"],
                name=body["job_id"],
                input=json.dumps(body),
            )
            log_event(logger, "workflow_started", job_id=body["job_id"])
        except Exception:
            logger.exception("workflow_start_failed")
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}

