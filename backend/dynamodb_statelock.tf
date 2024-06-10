# Frontend DB

resource "aws_dynamodb_table" "cloud_resume_frontend_terraform_state_lock" {
  name           = "cloud_resume_frontend_terraform_state_lock"
  billing_mode   = "PROVISIONED"
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags)
}



# Backend DB

resource "aws_dynamodb_table" "cloud_resume_prod_terraform_state_lock" {
  name           = "cloud_resume_backend_terraform_state_lock"
  billing_mode   = "PROVISIONED"
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags)
}