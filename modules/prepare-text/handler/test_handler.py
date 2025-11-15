"""Test handler module."""

__author__ = "Dave Hall <me@davehall.com.au>"
__copyright__ = "Copyright 2024, 2025, Skwashd Services Pty Ltd https://davehall.com.au"
__license__ = "MIT"

import uuid

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
        "arn:aws:lambda:us-east-1:123456789012:function:prepare_text"
    )
    mock_context._memory_limit_in_mb = 128
    mock_context._aws_request_id = uuid.uuid4().hex
    mock_context._log_group_name = "/aws/lambda/prepare_text"
    mock_context._log_stream_name = "2023/11/06/[LATEST]abcdef123456"

    return mock_context


@pytest.mark.parametrize(
    ("input", "expected"),
    [
        # Simple string
        ("This is a test", "this is a test"),
        # Multi line message
        ("This\nis\na\nmulti\nline\nmessage", "this is a multi line message"),
        # Remove "bad" line
        (
            "This is a multi line message\n\n-- \n\nSignature",
            "this is a multi line message signature",
        ),
        # Expand contractions
        ("I'm a test", "i am a test"),
        # Remove excessive whitespace
        (
            "This  is  a  test\n\n\n\n\n\nThis  is  a  test",
            "this is a test this is a test",
        ),
    ],
)
def test_handler(lambda_context: LambdaContext, input: str, expected: str) -> None:
    """Test lambda handler."""
    event = {"text": input}
    response = handler.handler(event, lambda_context)
    assert response == {
        "body": expected,
        "headers": {},
        "statusCode": 200,
    }


def test_handler_invalid_input(lambda_context: LambdaContext) -> None:
    """Test lambda handler with invalid input."""
    event = {"garbage": "input"}
    with pytest.raises(AttributeError):
        _ = handler.handler(event, lambda_context)


def test_load_text_cleanup_rules() -> None:
    """Test load_text_cleanup_rules function."""
    rules = handler.load_text_cleanup_rules()
    assert len(rules) > 0
    assert all("pattern" in rule for rule in rules)
    assert all("replace" in rule for rule in rules)


def test_prepare_text_custom_rules() -> None:
    """Test prepare_text function with custom rules."""
    text = "[EXTERNAL] Re: Here's my text to prepare\n\n\nLemme know wotcha think, alright?"
    rules = [
        {
            "pattern": r"^(\[external\] ?)?((re?s?|fyi|rif|fs|vb|rv|enc|odp|pd|ynt|ilt|sv|vs|vl|aw|wg|απ|σχετ|πρθ|תגובה|הועבר|主题|转发|fwd?|)([-:;]* ))",
            "replace": "",
        },
    ]
    cleaned_text = handler.prepare_text(text, rules)
    assert (
        cleaned_text == "here is my text to prepare let me know wotcha think, alright?"
    )
