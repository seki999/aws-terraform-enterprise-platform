import json
import logging
from datetime import UTC, datetime


def log_event(logger: logging.Logger, event: str, **fields: object) -> None:
    blocked_fields = {"password", "token", "secret"}
    safe = {key: value for key, value in fields.items() if key not in blocked_fields}
    logger.info(json.dumps({"timestamp": datetime.now(UTC).isoformat(), "event": event, **safe}))
