# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License


resource "aws_secretsmanager_secret" "db_user" {
  name_prefix = "db-${local.db_cluster_name}-user"

  description = "Database user secret for ${local.db_cluster_name}"
  kms_key_id  = var.kms_key_arn

  policy = data.aws_iam_policy_document.secret_db_user.json

  recovery_window_in_days = 7

  tags = var.tags
}

ephemeral "aws_secretsmanager_random_password" "db_user" {
  password_length = 32

  # Exclude characters that mess up bash commands
  exclude_characters = "!$?*@:&'\"`"
  include_space      = false
}

resource "aws_secretsmanager_secret_version" "db_user" {
  secret_id = aws_secretsmanager_secret.db_user.id

  secret_string_wo_version = 0 # Initial setup
  secret_string_wo = jsonencode({
    engine      = "postgres",
    host        = aws_rds_cluster.this.endpoint,
    username    = aws_rds_cluster.this.database_name,
    password    = ephemeral.aws_secretsmanager_random_password.db_user.random_password,
    dbname      = aws_rds_cluster.this.database_name,
    cluster_arn = aws_rds_cluster.this.arn, # This is non standard property is added for convenience

    dbClusterIdentifier = aws_rds_cluster.this.id,
  })

  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
}

data "aws_iam_policy_document" "secret_db_user" {

  statement {
    actions = [
      "secretsmanager:*"
    ]

    resources = ["*"]

    principals {
      type = "AWS"

      identifiers = [
        var.admin_role_arn,
        data.aws_caller_identity.current.account_id,
      ]
    }
  }

  /*
  FIXME: Configure this properly.
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
    ]

    resources = ["*"]

    principals {
      type = "AWS"

      identifiers = [

      ]
    }
  }
  */
}

data "aws_serverlessapplicationrepository_application" "rotate_secret" {
  # Application only available in us-east-1. More info https://serverlessrepo.aws.amazon.com/applications/us-east-1/297356227824/SecretsManagerRDSPostgreSQLRotationSingleUser
  application_id = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationSingleUser"
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "rotate_secret" {
  name             = "rotate-${aws_secretsmanager_secret.db_user.name}"
  application_id   = data.aws_serverlessapplicationrepository_application.rotate_secret.application_id
  semantic_version = data.aws_serverlessapplicationrepository_application.rotate_secret.semantic_version
  capabilities     = data.aws_serverlessapplicationrepository_application.rotate_secret.required_capabilities

  parameters = {
    endpoint     = "https://secretsmanager.${data.aws_region.current.name}.${data.aws_partition.current.dns_suffix}"
    functionName = "rotate-${aws_secretsmanager_secret.db_user.name}"
    kmsKeyArn    = var.kms_key_arn
  }
}
