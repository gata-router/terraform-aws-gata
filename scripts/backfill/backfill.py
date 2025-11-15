#!/usr/bin/env python3
"""Script to backfill the database with historical ticket data."""

__author__ = "Dave Hall <me@davehall.com.au>"
__copyright__ = "Copyright 2025 - 2026, Skwashd Services Pty Ltd https://gata.works"
__license__ = "MIT"

import datetime
import json
import logging
import os
import time
from collections.abc import Generator
from typing import Any

import boto3
import zenpy

import handler

logging.basicConfig(level=logging.INFO)
LOGGER = logging.getLogger(__name__)

BEDROCK = boto3.client("bedrock-runtime")
COMPREHEND = boto3.client("comprehend")
RDS = boto3.client("rds-data")
SECRETS = boto3.client("secretsmanager")
SSM = boto3.client("ssm")

LAST_TICKET_ID_FILE = "last_ticket_id.txt"

DB_SECRET_ARN = os.environ["DB_SECRET_ARN"]
DB_CONFIG = json.loads(SECRETS.get_secret_value(SecretId=DB_SECRET_ARN)["SecretString"])

GROUP_MAPPINGS = {}
SSM_GROUP_MAPPINGS = os.environ.get("SSM_GROUP_MAPPINGS")
if SSM_GROUP_MAPPINGS:
    GROUP_MAPPINGS = json.loads(
        SSM.get_parameter(Name=SSM_GROUP_MAPPINGS, WithDecryption=True)["Parameter"][
            "Value"
        ]
    )

ZENDESK_PARAM = os.environ["ZENDESK_PARAM"]
ZENDESK_SUBDOMAIN = os.environ["ZENDESK_SUBDOMAIN"]
ZENDESK_CREDS = json.loads(
    SSM.get_parameter(Name=ZENDESK_PARAM, WithDecryption=True)["Parameter"]["Value"]
)

SQL = """
INSERT INTO ticket (id, processed_data, via_channel, probability, routed_by, created, initial_group_id, initial_group_id_mapped, closed, closed_group_id, closed_group_id_mapped, embedding)
VALUES (:id, :processed_data, :via_channel::channel, 0.0, 'external'::router, :created, 0, 0, :closed, :closed_group_id::bigint, :closed_group_id_mapped::bigint, :embedding::vector)
"""

TEXT_CLEANUP_RULES = handler.load_text_cleanup_rules()


## DB FUNCTIONS ##


def db_connect() -> None:
    """
    Connect to the database.

    We're using Aurora Serverless, and so the database will hibernate. This function
    wakes up the database and ensures we can connect before proceeding.

    If there is another issue with the connection, it will fail here.
    """
    for _ in range(5):
        try:
            db_query("SELECT 1;", [])
            LOGGER.info("Connected to DB")
        except Exception:
            LOGGER.exception("Failed to connect to DB")
            LOGGER.info("Retrying DB connection in 5 seconds...")
            time.sleep(5)
        else:
            return

    raise RuntimeError("FATAL: Unable to connect to database.")  # noqa: TRY003 This is a simple script.


def db_query(query: str, parameters: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """
    Execute a query against the database.

    Args:
    ----
        query: The SQL query to execute.
        parameters: The parameters for the SQL query.

    Returns:
    -------
        The records returned by the query.

    """
    response = RDS.execute_statement(
        secretArn=DB_SECRET_ARN,
        database=DB_CONFIG["dbname"],
        resourceArn=DB_CONFIG["cluster_arn"],
        sql=query,
        parameters=parameters,
        formatRecordsAs="JSON",
    )
    return response.get("records", [])


def insert_ticket(ticket: zenpy.lib.api.Ticket) -> None:  # type: ignore[possibly-missing-attribute] Trust me, this will be set
    """
    Prepare data and insert a ticket record into the database.

    Args:
    ----
        ticket: The ticket to insert.

    """
    created_at = datetime.datetime.fromisoformat(ticket.created_at)
    updated_at = datetime.datetime.fromisoformat(ticket.updated_at)

    text = prepare_text(f"{ticket.raw_subject}\n{ticket.description}")
    embedding = generate_embeddings(text)

    params = [
        {"name": "id", "value": {"longValue": ticket.id}},
        {"name": "processed_data", "value": {"stringValue": text}},
        {"name": "via_channel", "value": {"stringValue": ticket.via.channel}},
        {"name": "created", "value": {"longValue": int(created_at.timestamp())}},
        {"name": "closed", "value": {"longValue": int(updated_at.timestamp())}},
        {
            "name": "closed_group_id",
            "value": {
                "stringValue": str(  # Needs to be a stringValue as this a bigint
                    ticket.group_id
                )
            },
        },
        {
            "name": "closed_group_id_mapped",
            "value": {
                "stringValue": str(  # Needs to be a stringValue as this a bigint
                    GROUP_MAPPINGS.get(str(ticket.group_id), ticket.group_id)
                )
            },
        },
        {"name": "embedding", "value": {"stringValue": embedding}},
    ]

    db_query(SQL, parameters=params)


## STATUS TRACKING FUNCTIONS ##


def get_last_processed_ticket_id() -> int:
    """
    Retrieve the last processed ticket ID.

    Returns:
    -------
        The last processed ticket ID or 0 this is the first run.

    """
    last_id = 0
    if os.path.exists(LAST_TICKET_ID_FILE):
        with open(LAST_TICKET_ID_FILE, encoding="utf-8") as f:
            last_id = int(f.read().strip())
    return last_id


def update_last_processed_ticket_id(ticket_id: int) -> None:
    """
    Update the last processed ticket ID.

    Args:
    ----
        ticket_id: The ID of the last ticket successfully processed.

    """
    with open(LAST_TICKET_ID_FILE, "w", encoding="utf-8") as f:
        f.write(str(ticket_id))


## ZENDESK FUNCTIONS ##


def get_tickets() -> Generator[zenpy.lib.api.Ticket]:  # type: ignore[possibly-missing-attribute]
    """Fetch tickets from Zendesk."""
    creds = {
        "email": ZENDESK_CREDS["username"],
        "token": ZENDESK_CREDS["password"],
        "subdomain": ZENDESK_SUBDOMAIN,
    }

    zenpy_client = zenpy.Zenpy(**creds)
    zenpy_client.disable_caching()  # Cache will exhaust memory.

    params = {
        "type": "ticket",
        "status": "closed",
        "updated_at_after": "1year",
        "sort_order": "desc",  # This has no impact, it is just here for clarity.
        "cursor_pagination": True,
    }

    yield from zenpy_client.search_export(**params)


## TEXT PROCESSING AND EMBEDDING FUNCTIONS ##


def prepare_text(text: str) -> str:
    """
    Prepare the text for embedding generation.

    Args:
    ----
        text: The text to process.

    Returns:
    -------
        The processed string.

    """
    if not text:
        return ""

    text = redact_pii(text)
    return handler.prepare_text(text, TEXT_CLEANUP_RULES)


def redact_pii(text: str) -> str:
    """
    Redact PII in the given text using Comprehend.

    Args:
    ----
        text: The text to process.

    Returns:
    -------
        The text with PII redacted.

    """
    if not text:
        return ""

    response = COMPREHEND.detect_pii_entities(Text=text, LanguageCode="en")

    pii_entities = response.get("Entities", [])
    if not pii_entities:
        return text

    entities = sorted(pii_entities, key=lambda x: int(x["EndOffset"]), reverse=True)
    for entity in entities:
        text = "".join(
            [
                text[: int(entity["BeginOffset"])],
                entity["Type"],
                text[int(entity["EndOffset"]) :],
            ]
        )

    return text


def generate_embeddings(text: str) -> str:
    """
    Get the embedding for the given text from Bedrock.

    Args:
    ----
        text: The text to generate the embedding for.

    Returns:
    -------
        The embedding as a string formatted for insertion into the database.

    """
    response = BEDROCK.invoke_model(
        modelId="amazon.titan-embed-text-v2:0",
        contentType="application/json",
        accept="application/json",
        body=json.dumps(
            {
                "inputText": text,
            }
        ),
    )

    response_body = json.loads(response["body"].read())
    embedding = response_body["embedding"]
    return "[" + ",".join(f"{value:.6f}" for value in embedding) + "]"


## LET'S DO THIS! ##


def main() -> None:
    """Orchestrate backfilling the database."""
    last_id = get_last_processed_ticket_id()

    db_connect()

    for ticket in get_tickets():
        if last_id > 0 and ticket.id >= last_id:
            LOGGER.info("Skipping already processed ticket ID: %s", ticket.id)
            continue

        LOGGER.info("Processing ticket ID: %s", ticket.id)

        insert_ticket(ticket)

        update_last_processed_ticket_id(ticket.id)

    LOGGER.info("Backfill complete")
    LOGGER.debug("Removing last processed ticket ID file")
    os.unlink(LAST_TICKET_ID_FILE)


if __name__ == "__main__":
    main()
