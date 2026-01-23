# Backend configuration
# Using local backend for simplicity in learning environment
# In production, use remote backend (S3, Terraform Cloud, etc.)

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
