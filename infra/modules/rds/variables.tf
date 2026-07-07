variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC the RDS instance and its security group live in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group (RDS is never public)."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group of the ECS tasks. This is the ONLY source allowed to reach the DB port."
  type        = string
}

variable "engine" {
  description = "Database engine."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version."
  type        = string
  default     = "16.4"
}

variable "port" {
  description = "Database port."
  type        = number
  default     = 5432
}

variable "instance_class" {
  description = "RDS instance class (sized per environment)."
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling in GB."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name to create."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Master password. In real usage inject from Secrets Manager / TF_VAR, never commit."
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ (prod)."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (per environment)."
  type        = number
}

variable "deletion_protection" {
  description = "Prevent accidental deletion (true in prod)."
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (true in dev, false in prod)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
