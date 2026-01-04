# S3 bucket outputs

output "ssm_logs_bucket_name" {
  description = "Name of the S3 bucket for SSM association logs"
  value       = aws_s3_bucket.ssm_logs.id
}

output "ssm_logs_bucket_arn" {
  description = "ARN of the S3 bucket for SSM association logs"
  value       = aws_s3_bucket.ssm_logs.arn
}

output "ssm_logs_bucket_region" {
  description = "AWS region of the S3 bucket"
  value       = aws_s3_bucket.ssm_logs.region
}
