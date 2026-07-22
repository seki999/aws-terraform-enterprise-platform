import importlib.util
import json
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock

ROOT = Path(__file__).parents[1]
sys.path.insert(0, str(ROOT / "layer" / "python"))
os.environ.setdefault("AWS_ACCESS_KEY_ID", "testing")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "testing")
os.environ.setdefault("AWS_DEFAULT_REGION", "ap-northeast-1")


def load_handler(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


def test_validator_rejects_missing_object_key(monkeypatch) -> None:
    monkeypatch.setenv("QUEUE_URL", "https://sqs.test/jobs")
    module = load_handler("validator_handler", ROOT / "validator" / "handler.py")
    result = module.handler({"body": json.dumps({"operation": "inspect"})}, None)
    assert result["statusCode"] == 400


def test_consumer_reports_only_failed_records(monkeypatch) -> None:
    monkeypatch.setenv("STATE_MACHINE_ARN", "arn:aws:states:region:account:stateMachine:test")
    module = load_handler("consumer_handler", ROOT / "consumer" / "handler.py")
    module.stepfunctions = MagicMock()
    module.stepfunctions.start_execution.side_effect = [None, RuntimeError("failed")]
    event = {
        "Records": [
            {"messageId": "ok", "body": json.dumps({"job_id": "a"})},
            {"messageId": "bad", "body": json.dumps({"job_id": "b"})},
        ]
    }
    assert module.handler(event, None) == {"batchItemFailures": [{"itemIdentifier": "bad"}]}


def test_worker_writes_completed_status(monkeypatch) -> None:
    monkeypatch.setenv("TABLE_NAME", "jobs")
    module = load_handler("worker_handler", ROOT / "step-worker" / "handler.py")
    module.dynamodb = MagicMock()
    result = module.handler({"job_id": "a", "created_at": "2026-01-01T00:00:00Z"}, None)
    assert result["status"] == "completed"
    module.dynamodb.put_item.assert_called_once()
