variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used as a naming prefix."
  type        = string
  default     = "hotel-platform"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

# --- Network -----------------------------------------------------------------
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

# --- ECS ---------------------------------------------------------------------
variable "container_image" {
  type    = string
  default = "nginx:1.27-alpine"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "task_cpu" {
  type    = string
  default = "256"
}

variable "task_memory" {
  type    = string
  default = "512"
}

# --- RDS ---------------------------------------------------------------------
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  description = "Master DB password. Provide via TF_VAR_db_password, never commit a real value."
  type        = string
  sensitive   = true
  default     = "ChangeMe_Dev_123!" # placeholder so plan works without a secret store
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 1
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}
