resource "aws_dynamodb_table" "cloud_resume_view_count_table" {
  name           = "cloud_resume_view_count_table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Statistics"

  attribute {
    name = "Statistics"
    type = "S"
  }

  tags = merge(var.tags)
}

resource "aws_dynamodb_table_item" "view_count" {
  table_name = aws_dynamodb_table.cloud_resume_view_count_table.name
  hash_key   = aws_dynamodb_table.cloud_resume_view_count_table.hash_key

  item       = <<ITEM
  {
    "Statistics": {"S": "view_count"},
    "Visitors": {"N": "0"}
  }
ITEM
  depends_on = [aws_dynamodb_table.cloud_resume_view_count_table]

  lifecycle {
    ignore_changes = [
      item
    ]
  }
}
