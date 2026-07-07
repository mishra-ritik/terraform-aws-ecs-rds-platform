# dev sizing: small + cheap, low durability guarantees
aws_region  = "ap-south-1"
project     = "hotel-platform"
environment = "dev"

# Network (single shared NAT to save cost)
vpc_cidr             = "10.10.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
single_nat_gateway   = true

# ECS (minimal footprint)
container_image = "nginx:1.27-alpine"
container_port  = 80
desired_count   = 1
task_cpu        = "256"
task_memory     = "512"

# RDS (small instance, short retention, no deletion protection)
db_instance_class       = "db.t3.micro"
db_allocated_storage    = 20
db_name                 = "appdb"
db_username             = "appuser"
db_multi_az             = false
backup_retention_period = 1
deletion_protection     = false
skip_final_snapshot     = true

# db_password: do NOT put a real secret here.
# Provide via environment: export TF_VAR_db_password='...'
