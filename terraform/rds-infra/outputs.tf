output "db_endpoint" {
  description = "RDS instance hostname — used by api-server and backend-worker"
  value       = module.rds.db_endpoint
}

output "db_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

output "db_username" {
  description = "Master database username"
  value       = module.rds.db_username
}

output "db_password_ssm_path" {
  description = "SSM parameter path for the DB password — fetch with: aws ssm get-parameter --with-decryption"
  value       = module.rds.db_password_ssm_path
}
