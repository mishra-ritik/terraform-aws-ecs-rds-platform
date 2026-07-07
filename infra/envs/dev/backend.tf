# -----------------------------------------------------------------------------
# Remote state backend (dev)
#
# Kept commented so the assessment can be reviewed with a purely local backend:
#   terraform init && terraform validate && terraform plan -refresh=false
#
# To use real remote state, create the S3 bucket + DynamoDB lock table first,
# then uncomment and run `terraform init -migrate-state`.
# -----------------------------------------------------------------------------
terraform {
  # backend "s3" {
  #   bucket         = "my-tfstate-dev"
  #   key            = "hotel-platform/dev/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "my-tfstate-locks"
  #   encrypt        = true
  # }
}
