resource "aws_cloudtrail" "cloud_resume_cloudtrail" {
  name           = "cloud_resume_cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloud_resume_cloudtrail_logs.id
  s3_key_prefix  = ""

  tags = merge(var.tags)

  depends_on = [
    aws_s3_bucket_policy.cloud_resume_cloudtrail_bucket_policy
  ]
}