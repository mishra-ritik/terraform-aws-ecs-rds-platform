variable "name_prefix" {
  description = "Prefix applied to all resource names (usually \"<project>-<env>\")."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones to spread subnets across."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ, hosts the ALB / NAT)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ, hosts ECS tasks and RDS)."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway (cheaper, dev) instead of one per AZ (HA, prod)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default     = {}
}
