"""Tests for the Lambda function."""

__author__ = "Dave Hall <me@davehall.com.au>"
__copyright__ = "Copyright 2024, 2025, Skwashd Services Pty Ltd https://davehall.com.au"
__license__ = "MIT"

import json
import os
import typing
import uuid
from typing import Any

import boto3
import moto
import pytest
from aws_lambda_powertools.utilities.typing.lambda_context import LambdaContext
from pydantic import ValidationError
from types_boto3_events.client import EventBridgeClient
from types_boto3_ssm.client import SSMClient

import handler.handler as handler
from handler.handler import (
    CaseInsensitiveStrEnum,
    Channel,
    TicketVia,
)

AUTH_HEADER = "Basic dGVzdF91c2VyOnRlc3RfcGFzc3dvcmQ="

EMPTY_CREDS = handler.Credentials({"username": "", "password": ""})


# Inspired by https://github.com/aws-powertools/powertools-lambda-python/issues/1169
class MockLambdaContext(LambdaContext):
    """Mock Lambda Context for testing purposes."""

    def __init__(self) -> None:
        """Initialize the mock context."""
        super().__init__()
        self._function_name = "mock_lambda_function"
        self._memory_limit_in_mb = 128
        self._invoked_function_arn = (
            "arn:aws:lambda:us-east-1:123456789012:function:mock_lambda_function"
        )
        self._aws_request_id = uuid.uuid4().hex


@pytest.fixture
def lambda_context() -> LambdaContext:
    """Mock Lambda Context object."""
    return MockLambdaContext()


@pytest.fixture
def _aws_credentials() -> None:
    """Ensure we're using fake AWS creds for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"  # noqa: S105 This isn't a real key
    os.environ["AWS_SECURITY_TOKEN"] = "testing"  # noqa: S105 This isn't a real token
    os.environ["AWS_SESSION_TOKEN"] = "testing"  # noqa: S105 This isn't a real token
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"


@pytest.fixture
def ssm(
    _aws_credentials: typing.Callable,
) -> typing.Generator[SSMClient]:
    """Set up mock System Manager client."""
    with moto.mock_aws():
        yield boto3.client("ssm")


@pytest.fixture
def events(
    _aws_credentials: typing.Callable,
) -> typing.Generator[EventBridgeClient]:
    """Set up mock EventBridge client."""
    with moto.mock_aws():
        events = boto3.client("events")
        events.create_event_bus(Name="zendesk-webhook-bus")
        yield events


@pytest.fixture
def _lambda_environment(ssm: SSMClient) -> None:
    """Set up environment variables for the Lambda function."""
    creds_key = "/zendesk/webhook_credentials"
    os.environ["CREDENTIALS_PARAM_PATH"] = creds_key
    os.environ["EVENT_BUS_NAME"] = "zendesk-webhook-bus"
    handler.SSM_PARAMS = {}
    ssm.put_parameter(
        Name=creds_key,
        Value=json.dumps({"username": "test_user", "password": "test_password"}),
        Type="SecureString",
        KeyId="alias/aws/ssm",
    )


@pytest.fixture
def mock_ticket() -> str:
    """Return a mock ticket as a JSON string."""
    return json.dumps(
        {
            "account_id": 12345,
            "detail": {
                "actor_id": 123456,
                "assignee_id": "4321",
                "brand_id": None,
                "created_at": "2022-11-22T22:11:22Z",
                "custom_status": 1234,
                "description": "Test ticket description",
                "external_id": None,
                "form_id": None,
                "group_id": "2468",
                "id": 24,
                "is_public": True,
                "organization_id": None,
                "priority": "normal",
                "requester_id": 1234,
                "status": "pending",
                "subject": "Test Ticket Subject",
                "submitter_id": None,
                "tags": "connecting_to_platform sample_ticket",
                "type": "incident",
                "updated_at": "2022-11-22T22:11:22Z",
                "via": {"channel": "web_form"},  # Updated: 'source' field removed
            },
            "event": {},
            "id": "de305d54-75b4-431b-adb2-eb6b9e546013",
            "subject": "ticket:24:created",
            "time": "2022-11-22T22:11:22Z",
            "type": "zen:event-type:ticket.created",
            "zendesk_event_version": "2022-11-22T22:11:22Z",
        }
    )


@pytest.fixture
def base_zendesk_event_data(mock_ticket: str) -> dict[str, typing.Any]:
    """Return a base Zendesk event data dictionary, ready for event-specific modifications."""
    return json.loads(mock_ticket)


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_handler(
    events: typing.Callable, lambda_context: handler.LambdaContext, mock_ticket: str
) -> None:
    """Test handler with valid signature."""
    event = {
        "headers": {
            "authorization": AUTH_HEADER,
        },
        "body": mock_ticket,
    }

    response = handler.handler(event, lambda_context)

    assert response["statusCode"] == 200
    assert json.loads(response["body"])["message"] == "Event processed successfully"


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_handler_missing_auth_header(
    events: typing.Callable, lambda_context: handler.LambdaContext, mock_ticket: str
) -> None:
    """Test handler with missing authorization header."""
    event = {
        "headers": {},
        "body": mock_ticket,
    }

    response = handler.handler(event, lambda_context)

    assert response["statusCode"] == 401
    assert json.loads(response["body"])["message"] == "Missing Authorization header"


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_verify_basic_auth_invalid_header(
    lambda_context: handler.LambdaContext,
) -> None:
    """Test handler with a non compliant header value."""
    assert handler.verify_basic_auth("Open Sesame", EMPTY_CREDS) is False


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_verify_basic_auth_broken_credentials(
    lambda_context: handler.LambdaContext,
) -> None:
    """Test handler with a non compliant header value."""
    assert (
        handler.verify_basic_auth("Basic dXNlcnBhc3M=", EMPTY_CREDS) is False
    )  # "userpass"


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_handler_invalid_credentials(lambda_context: handler.LambdaContext) -> None:
    """Test handler with invalid credentials."""
    event = {
        "headers": {
            "authorization": "Basic dXNlcjpwYXNz",  # "user:pass"
        },
        "body": '{"test":"data"}',
    }

    response = handler.handler(event, lambda_context)

    assert response["statusCode"] == 401
    assert json.loads(response["body"])["message"] == "Invalid credentials"


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_process_zendesk_webhook_invalid_json(
    lambda_context: handler.LambdaContext,
) -> None:
    """Test handler with invalid JSON payload."""
    event = {
        "headers": {
            "authorization": AUTH_HEADER,
        },
        "body": "invalid json",
    }

    response = handler.handler(event, lambda_context)

    assert response["statusCode"] == 400
    assert json.loads(response["body"])["message"] == "Invalid JSON payload"


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
@moto.mock_aws
def test_process_zendesk_webhook_eventbridge_error(
    events: EventBridgeClient, mock_ticket: str
) -> None:
    """Check that the function raises an exception when EventBridge.put_events() fails."""
    event = {
        "headers": {
            "authorization": AUTH_HEADER,
        },
        "body": mock_ticket,
    }

    # Delete the event bus to simulate an error
    events.delete_event_bus(Name="zendesk-webhook-bus")

    with pytest.raises(handler.ProcessingError) as exc_info:
        handler.process_zendesk_webhook(event)

    assert str(exc_info.value.message) == "Error processing event"


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@moto.mock_aws
def test_get_ssm_parameter_non_existent() -> None:
    """Test getting an SSM parameter that doesn't exist."""
    key = "/non/existent"
    with pytest.raises(handler.ProcessingError) as exc_info:
        handler.get_ssm_parameter(key)

    assert str(exc_info.value.message) == "Error retrieving parameter"


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
@moto.mock_aws
def test_get_ssm_parameter_call_twice(ssm: SSMClient) -> None:
    """Test calling get_ssm_parameter twice and that the value is cached."""
    assert handler.SSM_PARAMS == {}

    key = "/zendesk/webhook_credentials"

    shared_secret = handler.get_ssm_parameter(key)
    assert shared_secret == {"username": "test_user", "password": "test_password"}

    ssm.put_parameter(
        Name=key,
        Value="new_value",
        Type="SecureString",
        Overwrite=True,
    )

    shared_secret = handler.get_ssm_parameter(key)
    assert handler.SSM_PARAMS[key] == shared_secret


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_process_zendesk_webhook_invalid_data_structure(
    lambda_context: handler.LambdaContext,
) -> None:
    """Test handler with invalid data structure in the payload."""
    event = {
        "headers": {
            "authorization": AUTH_HEADER,
        },
        "body": json.dumps({"invalid": "structure"}),
    }

    response = handler.handler(event, lambda_context)

    assert response["statusCode"] == 400
    assert json.loads(response["body"])["message"] == "Invalid webhook data structure"


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_handler_invalid_webhook_data_structure(
    lambda_context: handler.LambdaContext,
) -> None:
    """Test handler with invalid data structure in the payload."""
    event = {
        "headers": {
            "authorization": AUTH_HEADER,
        },
        "body": json.dumps(
            {
                "account_id": "not_an_int",
                "detail": {},
                "event": {},
                "id": "uuid",
                "subject": "sub",
                "time": "time",
                "type": "type",
                "zendesk_event_version": "zv",
            }
        ),
    }
    response = handler.handler(event, lambda_context)
    assert response["statusCode"] == 400
    assert "Invalid webhook data structure" in json.loads(response["body"])["message"]


@pytest.mark.filterwarnings(
    "ignore::DeprecationWarning"
)  # "datetime.datetime.utcnow() is deprecated" coming from boto3
@pytest.mark.usefixtures("_lambda_environment")
def test_handler_unexpected_error(
    lambda_context: handler.LambdaContext,
    monkeypatch: pytest.MonkeyPatch,
    mock_ticket: str,
) -> None:
    """Test handler with an unexpected error during processing."""

    def mock_process_zendesk_webhook_raises_exception(
        *args: list[Any], **kwargs: dict[str, Any]
    ) -> None:
        """Mock function that raises an unexpected exception."""
        raise ValueError("Something broke unexpectedly")  # noqa: TRY003  # Message is needed for this exception.

    monkeypatch.setattr(
        handler,
        "process_zendesk_webhook",
        mock_process_zendesk_webhook_raises_exception,
    )

    event = {
        "headers": {"authorization": AUTH_HEADER},
        "body": mock_ticket,
    }
    response = handler.handler(event, lambda_context)
    assert response["statusCode"] == 500
    assert json.loads(response["body"])["message"] == "An unexpected error occurred"


@pytest.mark.parametrize(
    ("enum_class", "value", "expected"),
    [
        (handler.TicketPriority, "Low", handler.TicketPriority.low),
        (handler.TicketPriority, "NORMAL", handler.TicketPriority.normal),
        (handler.TicketStatus, "Closed", handler.TicketStatus.closed),
        (handler.TicketStatus, "OPEN", handler.TicketStatus.open),
        (handler.TicketType, "Incident", handler.TicketType.incident),
        (handler.TicketType, "TASK", handler.TicketType.task),
    ],
)
def test_case_insensitive_str_enum(
    enum_class: type[CaseInsensitiveStrEnum],
    value: str,
    expected: CaseInsensitiveStrEnum,
) -> None:
    """Test CaseInsensitiveStrEnum with valid values."""
    assert enum_class(value) == expected


def test_case_insensitive_str_enum_missing() -> None:
    """Test CaseInsensitiveStrEnum with an invalid value."""
    with pytest.raises(
        ValueError, match="'invalid_priority' is not a valid TicketPriority"
    ):
        handler.TicketPriority("invalid_priority")


@pytest.mark.parametrize(
    ("input_val", "expected_val"),
    [
        ("", 0),
        (None, 0),
        ("123", 123),
        ("0", 0),
    ],
)
def test_empty_str_to_zero(input_val: str | None, expected_val: int) -> None:
    """Test empty_str_to_zero with valid inputs."""
    assert handler._empty_str_to_zero(input_val) == expected_val


def test_empty_str_to_zero_invalid() -> None:
    """Test empty_str_to_zero with an invalid input."""
    with pytest.raises(
        ValueError, match="invalid literal for int\\(\\) with base 10: 'abc'"
    ):
        handler._empty_str_to_zero("abc")


@pytest.mark.parametrize(
    ("input_val", "expected_val"),
    [
        ("a b c", ["a", "b", "c"]),
        ("single", ["single"]),
        ("", []),
        (None, []),
        (["x", "y", "z"], ["x", "y", "z"]),
    ],
)
def test_str_to_list(
    input_val: str | list[str] | None, expected_val: list[str]
) -> None:
    """Test str_to_list with valid inputs."""
    assert handler._str_to_list(input_val) == expected_val


@pytest.mark.parametrize(
    ("input_val", "expected_val"),
    [
        (["1", "2", "3"], [1, 2, 3]),
        (["", "5"], [0, 5]),
        ([], []),
        (None, []),
    ],
)
def test_str_list_to_int_list(
    input_val: list[str] | None, expected_val: list[int]
) -> None:
    """Test str_list_to_int_list with valid inputs."""
    assert handler._str_list_to_int_list(input_val) == expected_val


def test_str_list_to_int_list_invalid_item() -> None:
    """Test str_list_to_int_list with an invalid item."""
    with pytest.raises(
        ValueError, match="invalid literal for int\\(\\) with base 10: 'abc'"
    ):
        handler._str_list_to_int_list(["1", "abc"])


def test_parse_zendesk_event_event_diff(base_zendesk_event_data: dict) -> None:
    """Test parsing a Zendesk event with an event diff."""
    base_zendesk_event_data["event"] = {"current": "new_value", "previous": "old_value"}
    base_zendesk_event_data["type"] = "zen:event-type:ticket.status_changed"
    event_obj = handler.ZendeskEvent(**base_zendesk_event_data)
    assert isinstance(event_obj.event, handler.EventDiff)
    assert event_obj.event.current == "new_value"


def test_parse_zendesk_event_comment_event(base_zendesk_event_data: dict) -> None:
    """Test parsing a Zendesk event with a comment added."""
    base_zendesk_event_data["event"] = {
        "comment": {
            "id": "123",
            "body": "This is a comment",
            "is_public": True,
            "author": {"id": "789", "is_staff": False, "name": "John Doe"},
        }
    }
    base_zendesk_event_data["type"] = "zen:event-type:ticket.comment_added"
    event_obj = handler.ZendeskEvent(**base_zendesk_event_data)
    assert isinstance(event_obj.event, handler.CommentEvent)
    assert event_obj.event.comment.body == "This is a comment"
    assert event_obj.event.comment.author is not None
    assert event_obj.event.comment.author.name == "John Doe"


def test_parse_zendesk_event_tags_event(base_zendesk_event_data: dict) -> None:
    """Test parsing a Zendesk event with tags added and removed."""
    base_zendesk_event_data["event"] = {
        "tags_added": ["new_tag"],
        "tags_removed": ["old_tag"],
    }
    base_zendesk_event_data["type"] = "zen:event-type:ticket.tags_changed"
    event_obj = handler.ZendeskEvent(**base_zendesk_event_data)
    assert isinstance(event_obj.event, handler.TagsEvent)
    assert "new_tag" in event_obj.event.tags_added


def test_parse_zendesk_event_empty_event(base_zendesk_event_data: dict) -> None:
    """Test parsing a Zendesk event with an empty event payload."""
    base_zendesk_event_data["event"] = {}
    base_zendesk_event_data["type"] = "zen:event-type:ticket.created"
    event_obj = handler.ZendeskEvent(**base_zendesk_event_data)
    assert isinstance(event_obj.event, handler.EmptyEvent)


def test_parse_webhook_data_valid(mock_ticket: str) -> None:
    """Test parsing valid webhook data, happy path."""
    parsed_data = handler.parse_webhook_data(mock_ticket)
    assert parsed_data.account_id == 12345
    assert parsed_data.detail.id == 24
    assert parsed_data.type == "zen:event-type:ticket.created"


def test_parse_webhook_data_invalid_json() -> None:
    """Test parsing webhook data with invalid JSON."""
    with pytest.raises(handler.ProcessingError) as exc_info:
        handler.parse_webhook_data("this is not json")
    assert exc_info.value.status_code == 400
    assert "Invalid JSON payload" in exc_info.value.message


def test_parse_webhook_data_validation_error() -> None:
    """Test parsing webhook data with invalid structure."""
    invalid_payload = json.dumps({"account_id": "not_an_int"})
    with pytest.raises(handler.ProcessingError) as exc_info:
        handler.parse_webhook_data(invalid_payload)
    assert exc_info.value.status_code == 400
    assert "Invalid webhook data structure" in exc_info.value.message


def test_prepare_event_data(mock_ticket: str) -> None:
    """Test preparing event data for EventBridge."""
    webhook_data = handler.parse_webhook_data(mock_ticket)
    prepared_event = handler.prepare_event_data(webhook_data)
    assert prepared_event["Source"] == "zendesk.com"
    assert prepared_event["DetailType"] == "ticket.created"
    assert webhook_data.subject in prepared_event["Resources"]
    assert webhook_data.subject.split(":")[1] in prepared_event["Resources"]
    detail_json = json.loads(prepared_event["Detail"])
    assert detail_json["account_id"] == webhook_data.account_id
    assert detail_json["detail"]["id"] == webhook_data.detail.id


def test_ticket_via_valid_channel() -> None:
    """Test TicketVia model with valid channel values."""
    valid_channels = [
        "web_form",
        "mail",
        "chat",
        "phone_call_inbound",
        "web_widget",
    ]
    for channel_val in valid_channels:
        ticket_via = TicketVia(channel=channel_val)  # type: ignore[arg-type] # str is valid here
        assert ticket_via.channel == channel_val
        # Ensure no other fields are present by converting to dict
        assert ticket_via.model_dump() == {"channel": channel_val}


def test_ticket_via_invalid_channel() -> None:
    """Test TicketVia model with invalid channel values."""
    invalid_channels = ["invalid_channel", "web", 123, None]
    for channel_val in invalid_channels:
        with pytest.raises(ValidationError):
            TicketVia(channel=channel_val)  # type: ignore[arg-type] # str is valid here


def test_ticket_via_extra_fields() -> None:
    """Test TicketVia model does not accept extra fields like 'source'."""
    with pytest.raises(ValidationError):
        TicketVia(channel="email", source={"rel": "test"})  # type: ignore[arg-type, call-arg] # Testing invalid values


@pytest.mark.parametrize(
    "channel_value",
    [
        "web_form",
        "mail",
        "chat",
        "logmein_rescue",
        "helpcenter",
        "user_merge",
        "api_phone_call_inbound",
        "line",
        "user_change",
        "churned_account",
        "telegram",
        "twitter_dm",
        "lotus",
    ],
)
def test_channel_literal_valid_values(channel_value: str) -> None:
    """Test that all valid Channel literal values are accepted."""

    # This test primarily serves to ensure the Channel literal is correctly defined
    # and that Pydantic can validate against it.
    # We create a simple model that uses the Channel type.
    class ModelWithChannel(handler.BaseModel):
        channel_field: Channel

    model_instance = ModelWithChannel(channel_field=channel_value)  # type: ignore[arg-type] # str is valid here
    assert model_instance.channel_field == channel_value


@pytest.mark.parametrize(
    "channel_value",
    [
        "email",
        "api",
        "unknown",
    ],
)
def test_channel_literal_invalid_value(channel_value: str) -> None:
    """Test that an invalid value for Channel literal raises ValidationError."""

    class ModelWithChannel(handler.BaseModel):
        channel_field: Channel

    with pytest.raises(ValidationError):
        ModelWithChannel(channel_field=channel_value)  # type: ignore[arg-type] # Testing invalid values
