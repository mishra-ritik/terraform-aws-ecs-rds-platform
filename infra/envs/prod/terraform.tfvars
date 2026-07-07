# prod sizing: larger + highly available, strong durability guarantees
aws_region  = "ap-south-1"
project     = "hotel-platform"
environment = "prod"

# Network (NAT per AZ for HA)
vpc_cidr             = "10.20.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]
single_nat_gateway   = false

# ECS (larger tasks, more replicas)
container_image = "nginx:1.27-alpine"
container_port  = 80
desired_count   = 3
task_cpu        = "512"
task_memory     = "1024"

# RDS (larger instance, Multi-AZ, long retention, deletion protection ON)
db_instance_class       = "db.t3.medium"
db_allocated_storage    = 100
db_name                 = "appdb"
db_username             = "appuser"
db_multi_az             = true
backup_retention_period = 30
deletion_protection     = true
skip_final_snapshot     = false

# db_password: do NOT put a real secret here.
# Provide via environment: export TF_VAR_db_password='...'
