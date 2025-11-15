# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  db_cluster_name = "${var.application_name}-${var.tags.environment}"
  db_setup_script = "${path.module}/setup.sql"

  sql_statements = [
    "CREATE USER ${aws_rds_cluster.this.database_name} WITH PASSWORD '${ephemeral.aws_secretsmanager_random_password.db_user.random_password}';",
    "GRANT ALL PRIVILEGES ON DATABASE ${aws_rds_cluster.this.database_name} TO ${aws_rds_cluster.this.database_name};",
    "GRANT ALL ON SCHEMA public TO ${aws_rds_cluster.this.database_name};",
    "GRANT ${aws_rds_cluster.this.database_name} TO ${aws_rds_cluster.this.master_username};",
    "ALTER DEFAULT PRIVILEGES FOR ROLE ${aws_rds_cluster.this.database_name} IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${aws_rds_cluster.this.database_name};",
    "ALTER DEFAULT PRIVILEGES FOR ROLE ${aws_rds_cluster.this.database_name} IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${aws_rds_cluster.this.database_name};",
    "ALTER DATABASE ${aws_rds_cluster.this.database_name} OWNER TO ${aws_rds_cluster.this.database_name};"
  ]
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = local.db_cluster_name
  database_name      = "gata"

  deletion_protection = true

  engine         = "aurora-postgresql"
  engine_version = "16.6"
  engine_mode    = "provisioned"

  master_username               = "dbadmin"
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  serverlessv2_scaling_configuration {
    min_capacity = var.scaling.min
    max_capacity = var.scaling.max
  }

  enable_http_endpoint = true

  backup_retention_period      = 14
  preferred_backup_window      = "13:00-15:00"
  preferred_maintenance_window = "sat:15:00-sat:17:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = local.db_cluster_name

  enabled_cloudwatch_logs_exports = [
    "postgresql",
  ]

  tags = var.tags

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      engine_version,
    ]
  }
}

resource "aws_rds_cluster_instance" "this" {
  identifier         = local.db_cluster_name
  cluster_identifier = aws_rds_cluster.this.id

  instance_class = "db.serverless"
  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version

  performance_insights_enabled    = true
  performance_insights_kms_key_id = var.kms_key_arn

  auto_minor_version_upgrade = true

  tags = var.tags
}

resource "aws_db_subnet_group" "this" {
  name       = local.db_cluster_name
  subnet_ids = [for s in data.aws_subnet.db : s.id]

  tags = var.tags
}

# trivy:ignore:AVD-AWS-0017 CWL-SSE is adquate for the data being logged.
resource "aws_cloudwatch_log_group" "db" {
  for_each = toset([
    "/aws/rds/cluster/${local.db_cluster_name}/postgresql",
  ])

  name              = each.value
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "terraform_data" "db_user" {
  triggers_replace = {
    never = "never"
  }

  provisioner "local-exec" {
    command = join("\n", [
      for s in local.sql_statements : <<-EOT
        aws rds-data execute-statement --resource-arn "$DB_ARN" --database "$DB_NAME" --secret-arn "$SECRET_ARN" --sql "${s}"
      EOT
    ])

    environment = {
      DB_ARN     = aws_rds_cluster.this.arn
      DB_NAME    = aws_rds_cluster.this.database_name
      SECRET_ARN = aws_rds_cluster.this.master_user_secret[0].secret_arn
    }

    interpreter = ["bash", "-c"]
  }

  depends_on = [
    aws_rds_cluster_instance.this,
    aws_secretsmanager_secret_version.db_user,
  ]
}

# Loosely based on https://advancedweb.hu/how-to-run-sql-scripts-against-the-rds-data-api-with-terraform/
resource "terraform_data" "db_schema" {
  triggers_replace = {
    file = filesha256(local.db_setup_script)
  }

  provisioner "local-exec" {
    command = <<-EOT
		  while read line; do
			  echo "$line"
				aws rds-data execute-statement --resource-arn "${aws_rds_cluster.this.arn}" --database "${aws_rds_cluster.this.database_name}" --secret-arn "${aws_rds_cluster.this.master_user_secret[0].secret_arn}" --sql "$line"
			done  < <(awk 'BEGIN{RS=";\n"}{gsub(/\n/,""); if(NF>0) {print $0";"}}' ${local.db_setup_script})
			aws rds-data execute-statement --resource-arn "${aws_rds_cluster.this.arn}" --database "${aws_rds_cluster.this.database_name}" --secret-arn "${aws_rds_cluster.this.master_user_secret[0].secret_arn}" --sql "ALTER TABLE ticket OWNER TO ${aws_rds_cluster.this.database_name}"
		EOT

    interpreter = ["bash", "-c"]
  }

  depends_on = [
    aws_rds_cluster_instance.this,
    terraform_data.db_user
  ]
}
