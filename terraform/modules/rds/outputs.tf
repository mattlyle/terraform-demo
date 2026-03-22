output "db_endpoint" {
  description = "RDS instance hostname"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Master database username"
  value       = aws_db_instance.this.username
}

output "db_password_ssm_path" {
  description = "SSM parameter path for the DB password (SecureString) — fetch with aws ssm get-parameter --with-decryption"
  value       = aws_ssm_parameter.db_password.name
}

output "db_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}
