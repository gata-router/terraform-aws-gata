"""Lambda function to process a Zendesk webhook and put the event on EventBridge event bus."""

__author__ = "Dave Hall <me@davehall.com.au>"
__copyright__ = "Copyright 2024, 2025, Skwashd Services Pty Ltd https://gata.works"
__license__ = "MIT"

import base64
import datetime
import json
import os
from collections.abc import Sequence
from enum import StrEnum, auto
from typing import Annotated, Any, Literal, NotRequired, TypedDict

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities import parameters
from aws_lambda_powertools.utilities.parameters.exceptions import GetParameterError
from aws_lambda_powertools.utilities.typing import LambdaContext
from botocore.exceptions import ClientError
from pydantic import UUID4, BaseModel, BeforeValidator, ValidationError, constr

try:
    from types_boto3_events.type_defs import PutEventsRequestEntryTypeDef
except ImportError:
    # Avoid needing to build a layer with the stubs
    class PutEventsRequestEntryTypeDef(TypedDict):  # type: ignore[no-redef] # Fallback for run time.
        """Type definition for PutEventsRequestEntry."""

        # Time: NotRequired[TimestampTypeDef] # noqa: ERA001 # We don't use this but keeping for reference.
        Source: NotRequired[str]
        Resources: NotRequired[Sequence[str]]
        DetailType: NotRequired[str]
        Detail: NotRequired[str]
        EventBusName: NotRequired[str]
        TraceHeader: NotRequired[str]


logger = Logger()

SSM_PARAMS: dict[str, Any] = {}

type Channel = Literal[
    "admin_setting",
    "answer_bot",
    "answer_bot_api",
    "answer_bot_for_agents",
    "answer_bot_for_sdk",
    "answer_bot_for_slack",
    "answer_bot_for_web_widget",
    "any_channel",
    "api_phone_call_inbound",
    "api_phone_call_outbound",
    "api_voicemail",
    "apple_business_chat",
    "automatic_solution_suggestions",
    "batch",
    "blog",
    "business_messaging_slack_connect",
    "chat",
    "chat_offline_message",
    "chat_transcript",
    "churned_account",
    "closed_ticket",
    "connect_ipm",
    "connect_mail",
    "connect_sms",
    "dropbox",
    "facebook_message",
    "facebook_post",
    "get_satisfaction",
    "github",
    "google_business_messages",
    "google_rcs",
    "group_change",
    "group_deletion",
    "helpcenter",
    "import",
    "instagram_dm",
    "iphone",
    "kakaotalk",
    "line",
    "linked_problem",
    "logmein_rescue",
    "lotus",
    "macro_reference",
    "mail",
    "mailgun",
    "merge",
    "messagebird_sms",
    "mobile",
    "mobile_sdk",
    "monitor_event",
    "native_messaging",
    "omnichannel",
    "phone_call_inbound",
    "phone_call_outbound",
    "recovered_from_suspended_tickets",
    "resource_push",
    "rule",
    "rule_revision",
    "sample_interactive_ticket",
    "sample_ticket",
    "satisfaction_prediction",
    "side_conversation",
    "sms",
    "sunshine_conversations_api",
    "sunshine_conversations_facebook_messenger",
    "sunshine_conversations_twitter_dm",
    "symphony",
    "telegram",
    "text_message",
    "ticket_sharing",
    "ticket_tagging",
    "topic",
    "twilio_sms",
    "twitter",
    "twitter_dm",
    "twitter_favorite",
    "user_change",
    "user_deletion",
    "user_merge",
    "viber",
    "voicemail",
    "web_form",
    "web_service",
    "web_widget",
    "wechat",
    "whatsapp",
]

type EventType = Literal[
    "zen:event-type:ticket.agent_assignment_changed",
    "zen:event-type:ticket.attachment_linked_to_comment",
    "zen:event-type:ticket.attachment_redacted_from_comment",
    "zen:event-type:ticket.brand_changed",
    "zen:event-type:ticket.comment_added",
    "zen:event-type:ticket.comment_made_private",
    "zen:event-type:ticket.comment_redacted",
    "zen:event-type:ticket.custom_field_changed",
    "zen:event-type:ticket.custom_status_changed",
    "zen:event-type:ticket.description_changed",
    "zen:event-type:ticket.external_id_changed",
    "zen:event-type:ticket.email_ccs_changed",
    "zen:event-type:ticket.followers_changed",
    "zen:event-type:ticket.form_changed",
    "zen:event-type:ticket.group_assignment_changed",
    "zen:event-type:ticket.organization_changed",
    "zen:event-type:ticket.priority_changed",
    "zen:event-type:ticket.problem_link_changed",
    "zen:event-type:ticket.requester_changed",
    "zen:event-type:ticket.status_changed",
    "zen:event-type:ticket.subject_changed",
    "zen:event-type:ticket.submitter_changed",
    "zen:event-type:ticket.tags_changed",
    "zen:event-type:ticket.task_due_at_changed",
    "zen:event-type:ticket.created",
    "zen:event-type:ticket.marked_as_spam",
    "zen:event-type:ticket.merged",
    "zen:event-type:ticket.permanently_deleted",
    "zen:event-type:ticket.soft_deleted",
    "zen:event-type:ticket.type_changed",
    "zen:event-type:ticket.sla_policy_changed",
    "zen:event-type:ticket.schedule_changed",
    "zen:event-type:ticket.ola_policy_changed",
]


type ConstrainedLowerStr = Annotated[str, constr(to_lower=True)]


# Borrowed from https://github.com/pydantic/pydantic/discussions/2687#discussioncomment-9893991
def _empty_str_to_zero(v: str | None) -> int:
    if v is None or v == "":
        return 0
    return int(v)


type EmptyStringToZero = Annotated[int, BeforeValidator(_empty_str_to_zero)]


def _str_to_list(v: str | list[str] | None) -> list[str]:
    if type(v) is list:
        return v
    if isinstance(v, str) and v.strip():
        return v.split(" ")
    return []


def _str_list_to_int_list(v: list[str] | None) -> list[int]:
    if v is None:
        return []
    return [_empty_str_to_zero(item) for item in v]


type StrToList = Annotated[list[str], BeforeValidator(_str_to_list)]
type StrListToIntList = Annotated[list[int], BeforeValidator(_str_list_to_int_list)]


class CaseInsensitiveStrEnum(StrEnum):
    """Base class for case-insensitive enums."""

    @classmethod
    def _missing_(cls, value: object) -> str | None:
        for member in cls:
            if member.value == str(value).lower():
                return member
        return None


class EventDiff(BaseModel):
    """Event data showing current and previous values."""

    current: str | bool | int | float | None = None
    previous: str | bool | int | float | None = None


class TicketPriority(CaseInsensitiveStrEnum):
    """Zendesk ticket priority values."""

    low = auto()
    normal = auto()
    high = auto()
    urgent = auto()


class TicketStatus(CaseInsensitiveStrEnum):
    """
    Zendesk ticket status values.

    Source https://developer.zendesk.com/api-reference/webhooks/event-types/ticket-events/#status-changed
    """

    archived = auto()
    closed = auto()
    deleted = auto()
    hold = auto()
    new = auto()
    open = auto()
    pending = auto()
    scrubbed = auto()
    solved = auto()


class TicketType(CaseInsensitiveStrEnum):
    """Zendesk ticket type values."""

    incident = auto()
    problem = auto()
    question = auto()
    task = auto()


class TicketVia(BaseModel):
    """Model for ticket via data."""

    channel: Channel


class Ticket(BaseModel):
    """Model for ticket event data."""

    actor_id: int | EmptyStringToZero
    assignee_id: int | EmptyStringToZero
    brand_id: int | EmptyStringToZero
    created_at: datetime.datetime
    custom_status: int | EmptyStringToZero
    description: str
    external_id: str | None
    form_id: int | EmptyStringToZero
    group_id: int | EmptyStringToZero
    id: int | EmptyStringToZero
    is_public: bool
    organization_id: int | EmptyStringToZero
    priority: TicketPriority | None = None
    requester_id: int
    status: TicketStatus
    subject: str
    submitter_id: int | EmptyStringToZero
    tags: StrToList
    type: TicketType | None = None
    updated_at: datetime.datetime
    via: TicketVia


class CommentAuthor(BaseModel):
    """Model for comment author data."""

    id: int | EmptyStringToZero
    is_staff: bool
    name: str


class CommentAttachment(BaseModel):
    """Model for comment attachment data."""

    id: int | EmptyStringToZero
    content_type: str | None = None
    content_url: str | None = None
    filename: str | None = None
    is_public: bool | None = None


class Comment(BaseModel):
    """Model for comment data."""

    id: int | EmptyStringToZero
    body: str | None = None
    is_public: bool
    author: CommentAuthor | None = None
    attachment: CommentAttachment | None = None


class CustomField(BaseModel):
    """Model for custom field configuration."""

    id: str
    title: str
    type: str


class CustomFieldValue(BaseModel):
    """Model for custom field value data."""

    value: str | int | float | bool | None = None
    id: str | None = None
    relationship_target: str | None = None


class CommentEvent(BaseModel):
    """Comments."""

    comment: Comment


class CustomFieldEvent(BaseModel):
    """Custom field changes."""

    current: CustomFieldValue
    previous: CustomFieldValue
    custom_field: CustomField


class UserListEvent(BaseModel):
    """User list changes (followers, email CCs)."""

    users_added: StrListToIntList
    users_removed: StrListToIntList


class TagsEvent(BaseModel):
    """Tag changes."""

    tags_added: list[str]
    tags_removed: list[str]


class MergedEvent(BaseModel):
    """Ticket merge."""

    target_ticket_id: int | EmptyStringToZero


class EmptyEvent(BaseModel):
    """Empty event with no additional data."""

    pass


# Union type for all possible event data
EventData = (
    EmptyEvent
    | CommentEvent
    | CustomFieldEvent
    | EventDiff
    | MergedEvent
    | TagsEvent
    | UserListEvent
)


class ZendeskEvent(BaseModel):
    """Zendesk event model."""

    account_id: int
    detail: Ticket
    event: EventData
    id: UUID4
    subject: str
    time: datetime.datetime
    type: EventType
    zendesk_event_version: datetime.datetime


class ProcessingError(Exception):
    """Exception raised for processing errors."""

    def __init__(self, message: str, status_code: int) -> None:
        """
        Initialize the exception.

        Args:
        ----
        message: The error message.
        status_code: The HTTP status code.

        """
        self.message = message
        self.status_code = status_code
        super().__init__(message, status_code)


class Credentials(TypedDict):
    """Type definition for credentials."""

    username: str
    password: str


def get_ssm_parameter(parameter_name: str) -> dict[str, str]:
    """
    Fetch a parameter from AWS Systems Manager Parameter Store.

    Args:
    ----
    parameter_name: The name of the parameter to retrieve.

    Returns:
    -------
    The value of the parameter.

    Raises:
    ------
    ProcessingError: If there's an error retrieving the parameter.

    """
    global SSM_PARAMS  # noqa: PLW0602 We update a key, so ruff is confused
    if SSM_PARAMS.get(parameter_name) is not None:
        return SSM_PARAMS[parameter_name]

    try:
        SSM_PARAMS[parameter_name] = parameters.get_parameter(
            parameter_name, transform="json", decrypt=True
        )

    except GetParameterError as e:
        logger.exception("Error retrieving parameter")
        raise ProcessingError("Error retrieving parameter", 500) from e  # noqa: TRY003 ProcessingError is a generic exception that needs a message

    return SSM_PARAMS[parameter_name]


def verify_basic_auth(header: str, expected_credentials: Credentials) -> bool:
    """
    Verify the basic authentication header.

    Args:
    ----
    header: The header value.
    expected_credentials: The expected credentials.

    Returns:
    -------
    True if the header is valid, False otherwise.

    """
    if not header.startswith("Basic "):
        logger.warning("Invalid Authorization header supplied by user")
        return False

    encoded_credentials = header[len("Basic ") :]
    credentials = base64.b64decode(encoded_credentials).decode("utf-8")

    supplied_creds = credentials.split(":", 1)
    if len(supplied_creds) != 2:
        logger.warning("Invalid credentials supplied by user")
        return False

    username, password = supplied_creds

    return (
        username == expected_credentials["username"]
        and password == expected_credentials["password"]
    )


def validate_auth(headers: dict[str, str]) -> None:
    """
    Validate the authentication header.

    Args:
    ----
    headers: The request headers.

    Raises:
    ------
    ProcessingError: If authentication fails.

    """
    auth_header = headers.get("authorization")
    if not auth_header:
        logger.error("Missing Authorization header")
        raise ProcessingError("Missing Authorization header", 401)  # noqa: TRY003 ProcessingError is a generic exception that needs a message

    param = get_ssm_parameter(os.environ["CREDENTIALS_PARAM_PATH"])
    creds = Credentials({"username": param["username"], "password": param["password"]})
    if not verify_basic_auth(auth_header, creds):
        logger.error("Invalid credentials")
        raise ProcessingError("Invalid credentials", 401)  # noqa: TRY003 ProcessingError is a generic exception that needs a message


def parse_webhook_data(payload: str) -> ZendeskEvent:
    """
    Parse and validate the webhook payload.

    Args:
    ----
    payload: The raw webhook payload as a string.

    Returns:
    -------
    ZendeskEvent: The parsed and validated webhook data.

    Raises:
    ------
    ProcessingError: If the payload is invalid.

    """
    try:
        data = json.loads(payload)
        return ZendeskEvent(**data)
    except json.JSONDecodeError as e:
        logger.exception("Invalid JSON payload")
        raise ProcessingError("Invalid JSON payload", 400) from e  # noqa: TRY003 ProcessingError is a generic exception that needs a message
    except ValidationError as e:
        logger.exception("Invalid webhook data structure")
        raise ProcessingError("Invalid webhook data structure", 400) from e  # noqa: TRY003 ProcessingError is a generic exception that needs a message


def prepare_event_data(event_data: ZendeskEvent) -> PutEventsRequestEntryTypeDef:
    """
    Prepare the event data for EventBridge.

    Args:
    ----
    event_data: The parsed webhook data.

    Returns:
    -------
    dict: The prepared event data.

    """
    return PutEventsRequestEntryTypeDef({
        "Source": "zendesk.com",
        "Resources": [event_data.subject, event_data.subject.split(":")[1]],
        "DetailType": event_data.type[15:],
        "Detail": event_data.model_dump_json(),
        "EventBusName": os.environ["EVENT_BUS_NAME"],
    })


def send_to_eventbridge(event_data: PutEventsRequestEntryTypeDef) -> None:
    """
    Send the event data to EventBridge.

    Args:
    ----
    event_data: The prepared event data.

    Raises:
    ------
    ProcessingError: If there's an error sending the event to EventBridge.

    """
    eventbridge = boto3.client("events")
    try:
        eventbridge.put_events(Entries=[event_data])
    except ClientError as e:
        logger.exception("Error putting event on EventBridge")
        raise ProcessingError("Error processing event", 500) from e  # noqa: TRY003 ProcessingError is a generic exception that needs a message


def process_zendesk_webhook(event: dict[str, Any]) -> str:
    """
    Process a Zendesk webhook event.

    Args:
    ----
    event: The event data.

    Returns:
    -------
    A message indicating the result of the processing.

    Raises:
    ------
    ProcessingError: If there's an error during processing.

    """
    validate_auth(event.get("headers", {}))
    webhook_data = parse_webhook_data(event["body"])
    event_data = prepare_event_data(webhook_data)
    send_to_eventbridge(event_data)
    logger.info(
        "Event processed successfully",
        extra={"ticket_id": webhook_data.detail.id},
    )
    return "Event processed successfully"


@logger.inject_lambda_context(log_event=True)
def handler(event: dict[str, Any], _: LambdaContext) -> dict[str, Any]:
    """
    Lambda handler function.

    Args:
    ----
    event: The event data.
    _: The Lambda context (unused).

    Returns:
    -------
    A response indicating the result of the processing.

    """
    try:
        result = process_zendesk_webhook(event)
        return {"statusCode": 200, "body": json.dumps({"message": result})}
    except ProcessingError as e:
        print(e.message)
        logger.exception("Error processing webhook %s", e.message)
        return {
            "statusCode": e.status_code,
            "body": json.dumps({"message": e.message}),
        }
    except Exception:
        logger.exception("Unexpected error")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "An unexpected error occurred"}),
        }
