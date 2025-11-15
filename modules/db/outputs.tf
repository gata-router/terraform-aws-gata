# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

output "cluster_arn" {
  description = "ARN of the database cluster"
  value       = aws_rds_cluster.this.arn
}

output "db_endpoints" {
  description = "Endpoints for the database cluster"
  value = {
    ro = aws_rds_cluster.this.reader_endpoint
    rw = aws_rds_cluster.this.endpoint
  }
}

output "db_name" {
  description = "Name of the default database"
  value       = aws_rds_cluster.this.database_name
}

output "db_security_group" {
  description = "Security group for the database cluster"
  value       = aws_security_group.db.id
}

output "secrets" {
  description = "ARN of the secret for the admin user"
  value = {
    admin = aws_rds_cluster.this.master_user_secret[0].secret_arn
    user  = aws_secretsmanager_secret.db_user.arn
  }
}
