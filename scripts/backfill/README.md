# Backfill Script

Backfill your database with the last 12 months worth of ticket data. This prepares the database for your first training run.

## Preparation

Before you can run this script you will need the following information:

* ARN of the DB user secret. This is the one created by Terraform. It doesn't contain an exclamation mark (`!`). Use this below instead of `<DB-USER-SECRET>`
* Subdomain of your Zendesk tenant. Just the subdomain portion - if you use `something.zendesk.com`, then the value for `<ZENDESK-DOMAIN>` would be `something`. Don't include the `.zendesk.com`
* Name of the Systems Manager Parameter Store parameter (aka SSM Param) used to store your Zendesk credentials. If you followed the quick start guide, it should be `/picofun/zendesk/credentials-http`. This is the value for `<ZENDESK-PARAM>` in step 4 below

You will also need an AWS session that has access to the following actions:

* `bedrock:InvokeModel` for the titan embeddings model
* `comprehend:DetectPiiEntities` to allow detecting PII in the tickets
* `rds-data:ExecuteStatement` on the GATA db cluster so we can run the database queries
* `secretsmanager:GetSecretValue` on the DB user secret so it can read the secret
* `kms:Decrypt` on the GATA key so it can decrypt the secret and SSM param
* `ssm:GetParameter` for the Zendesk credentials param

## Usage

To use this script perform the following actions:

1. Open a terminal in this directory. If needed, run `cd /path/to/gata/scripts/backfill`
2. Copy the text preparation Lambda handler: `cp ../../modules/prepare-text/handler/handler.py .` The script needs some of the functions included in the handler.
3. Install the dependencies: `uv sync`
4. Set environment variables: `export DB_SECRET_ARN='<DB-USER-SECRET>' ZENDESK_SUBDOMAIN='<ZENDESK-DOMAIN>' ZENDESK_PARAM='<ZENDESK-PARAM>'`
5. Run the script with `uv run ./backfill.py`
6. Make a cup of tea
7. Read some content
8. Wait a bit more. Yes, it will take a while
9. Go outside, touch grass or something
10. Celebrate when it completes