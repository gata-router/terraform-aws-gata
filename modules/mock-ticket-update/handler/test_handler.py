"""Test handler module."""

__author__ = "Dave Hall <me@davehall.com.au>"
__copyright__ = "Copyright 2024, 2025, Skwashd Services Pty Ltd https://gata.works"
__license__ = "MIT"

import uuid
from typing import Any

import pytest
from aws_lambda_powertools.utilities.typing import LambdaContext

import handler


@pytest.fixture
def lambda_context() -> LambdaContext:
    """Mock Lambda Context object."""
    mock_context: LambdaContext = LambdaContext()
    mock_context._function_name = "lambda_handler"
    mock_context._function_version = "$LATEST"
    mock_context._invoked_function_arn = (
        "arn:aws:lambda:us-east-1:123456789012:function:mock_zendesk_update"
    )
    mock_context._memory_limit_in_mb = 128
    mock_context._aws_request_id = uuid.uuid4().hex
    mock_context._log_group_name = "/aws/lambda/mock_zendesk_update"
    mock_context._log_stream_name = "2023/11/06/[LATEST]abcdef123456"

    return mock_context


def test_handler(lambda_context: LambdaContext) -> None:
    """Test lambda handler."""
    event: dict[str, Any] = {
        "path": {"ticket_id": 123},
        "payload": {"ticket": {"group_id": 456}},
    }
    response = handler.handler(event, lambda_context)
    body = response["body"]

    assert response["statusCode"] == 200
    assert body["ticket"]["id"] == 123
    assert body["audit"]["events"][0]["field_name"] == "group_id"
    assert body["audit"]["events"][0]["type"] == "Change"
    assert body["audit"]["events"][0]["value"] == 456


def test_handler_missing_payload(lambda_context: LambdaContext) -> None:
    """Test lambda handler without payload."""
    event: dict[str, Any] = {
        "path": {"ticket_id": 123},
    }
    with pytest.raises(KeyError):
        handler.handler(event, lambda_context)


def test_handler_missing_path(lambda_context: LambdaContext) -> None:
    """Test lambda handler without path."""
    event: dict[str, Any] = {
        "payload": {"ticket": {"group_id": 456}},
    }
    with pytest.raises(KeyError):
        handler.handler(event, lambda_context)
