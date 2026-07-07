output "db_security_group_id" {
  description = "Security group ID of the RDS instance."
  value       = aws_security_group.rds.id
}

output "db_endpoint" {
  description = "Connection endpoint (host:port) of the RDS instance."
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "db_port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}
