# SSM + Ansible Integration IAM Resources
#
# This module creates IAM roles and policies for EC2 instances
# managed by AWS Systems Manager (SSM) and Ansible.

# IAM Role for SSM + Ansible managed EC2 instances
resource "aws_iam_role" "ssm_ansible_role" {
  name = "ssm-ansible-ec2-role"

  description = "IAM role for EC2 instances managed by SSM + Ansible"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "ssm-ansible-ec2-role"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }
}

# Attach AmazonSSMManagedInstanceCore policy for SSM access
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm_ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatchAgentServerPolicy for CloudWatch monitoring
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ssm_ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom inline policy for Parameter Store read access
resource "aws_iam_role_policy" "parameter_store_read" {
  name = "parameter-store-read"
  role = aws_iam_role.ssm_ansible_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/study-ssm-ansible/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Custom inline policy for S3 logs write access
resource "aws_iam_role_policy" "s3_logs_write" {
  name = "s3-logs-write"
  role = aws_iam_role.ssm_ansible_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::study-ssm-ansible-logs-${var.aws_account_id}/associations/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::study-ssm-ansible-logs-${var.aws_account_id}"
      }
    ]
  })
}

# Instance Profile for EC2 instances
resource "aws_iam_instance_profile" "ssm_ansible_profile" {
  name = "ssm-ansible-instance-profile"
  role = aws_iam_role.ssm_ansible_role.name

  tags = {
    Name        = "ssm-ansible-instance-profile"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }
}
