"""Mock ticket update handler lamba function."""

__author__ = "Dave Hall <me@davehall.com.au>"
__copyright__ = "Copyright 2024, 2025, Skwashd Services Pty Ltd https://gata.works"
__license__ = "MIT"

import random
from typing import Any

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()


@logger.inject_lambda_context(log_event=True)
def handler(event: dict, _: LambdaContext) -> dict[str, Any]:
    """
    Mock the ticket update handler.

    This is done so we can run the ticket router in report only mode without needing
    to update the Step Function logic. The input and output matches the picofun ticket
    update lambda.

    Args:
    ----
        event: Event payload.
        _: LambdaContext: AWS Lambda Context object.

    Returns:
    -------
        str: JSON response.

    """
    payload = event["payload"]
    ticket_id = int(event["path"]["ticket_id"])
    group_id = int(payload["ticket"]["group_id"])

    body = {
        "audit": {
            "events": [
                {
                    "field_name": "group_id",
                    "id": random.randint(1, 999_999_999_999),  # noqa S311 Not a cryptographic function
                    "type": "Change",
                    "value": group_id,
                },
            ]
        },
        "ticket": {
            "id": ticket_id,
            "requester_id": random.randint(1, 100_000),  # noqa S311 Not a cryptographic function
            "status": "open",
            "subject": "[REDACTED]",
        },
    }

    response = {
        "statusCode": 200,
        "headers": {},  # Headers aren't important
        "body": body,
    }

    logger.info("Response: %s", response)

    return response
