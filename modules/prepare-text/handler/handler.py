"""Lambda function that prepares the ticket text for inference and converting to vectors."""

__author__ = "Dave Hall <me@davehall.com.au>"
__copyright__ = "Copyright 2024, 2025, Skwashd Services Pty Ltd https://davehall.com.au"
__license__ = "MIT"


import re
from typing import Any

import contractions  # type: ignore[import-untyped] # Contractions has no type hints
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

EXCLUDED_LINE_PREFIXES = (
    "-- ",  # Signature delimiter
    "bcc: ",
    "cc: ",
    "cell: ",  # Zendesk default template signature block
    "date: ",
    "email: ",
    "from: ",
    "regards,",  # Zendesk default template signature block
    "sent: ",
    "subject: ",
    "to: ",
)


def load_text_cleanup_rules() -> list[dict[str, str]]:
    """
    Get a list of text cleanup rules.

    Returns
    -------
        A list regex patterns to apply to strings.

    """
    # TODO Make this dynamic using SSM or args
    return [
        {
            # Remove proofpoint wrapper from URLs
            "pattern": r"https://urldefense.com/v3/__(.+)__;!!.*\$",
            "replace": r"\1",
        },
        {
            # Remove email subject garbage - modified version of followup to https://stackoverflow.com/a/11640925/5895246
            "pattern": r"^(\[external\] ?)?((re?s?|fyi|rif|fs|vb|rv|enc|odp|pd|ynt|ilt|sv|vs|vl|aw|wg|απ|σχετ|πρθ|תגובה|הועבר|主题|转发|fwd?|)([-:;]* ))",
            "replace": "",
        },
        {
            # Only keep the characters BERT cares about
            "pattern": r"[^a-z0-9?.! ]+",
            "replace": " ",
        },
        {
            # We only want a single space between words to simplify tokenization
            "pattern": r"\s+",
            "replace": " ",
        },
    ]


def prepare_text(text: str, rules: list[dict[str, str]]) -> str:
    """
    Prepare text for training, inference, and/or vectorisation.

    Args:
    ----
        text: The ticket title and body as a single string.
        rules: A list of text cleanup rules.

    Returns:
    -------
        The processed string.

    """
    # Reusing the text variable saves a bit of memory
    text = text.lower()
    text = contractions.fix(text)
    text = strip_bad_lines(text)

    for rule in rules:
        text = re.sub(rule["pattern"], rule["replace"], text)

    return text


def strip_bad_lines(in_text: str) -> str:
    """
    Remove lines that are repetive and/or add no value to the dataset.

    Args:
    ----
        in_text: The text to clean.

    Returns:
    -------
        The cleaned text.

    """
    out_text = []

    for line in in_text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith(EXCLUDED_LINE_PREFIXES):
            continue
        out_text.append(stripped)

    return " ".join(out_text)


@logger.inject_lambda_context(log_event=True)
def handler(event: dict, _: LambdaContext) -> dict[str, Any]:
    """
    Clean up the ticket text for inference and vectorisation.

    Args:
    ----
        event: Event payload.
        _: LambdaContext: AWS Lambda Context object.

    Returns:
    -------
        str: JSON response.

    """
    if "text" not in event:
        logger.error("No text in event")
        raise AttributeError(  # noqa TRY003 We need an error message
            "Property `text` not in event", obj="event", name="text"
        )

    text = event["text"]
    logger.debug("Text: %s", text)

    rules = load_text_cleanup_rules()
    logger.debug("Text cleanup rules: %s", rules)

    cleaned_text = prepare_text(text, rules)
    logger.info("Returned %d characters of text", len(cleaned_text))
    logger.debug("Cleaned text: %s", cleaned_text)

    response = {
        "body": cleaned_text,
        "headers": {},  # Headers aren't important
        "statusCode": 200,
    }
    logger.debug("Response: %s", response)

    return response
