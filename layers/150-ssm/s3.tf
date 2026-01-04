# S3 bucket for SSM association logs

resource "aws_s3_bucket" "ssm_logs" {
  bucket = "study-ssm-ansible-logs-${var.aws_account_id}"

  tags = {
    Name = "study-ssm-ansible-ssm-logs"
    Type = "SSM-Association-Logs"
  }
}

resource "aws_s3_bucket_public_access_block" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_versioning" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  target_bucket = aws_s3_bucket.ssm_logs.id
  target_prefix = "logs/"
}
