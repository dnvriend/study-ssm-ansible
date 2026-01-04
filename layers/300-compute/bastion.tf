# 300-compute - Bastion Host
#
# EC2 instance for bastion host (SSH jump host)

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.bastion_instance_type

  # Place in first public subnet for consistency
  subnet_id = data.terraform_remote_state.network.outputs.public_subnet_ids[0]

  # Attach bastion security group
  vpc_security_group_ids = [
    data.terraform_remote_state.network.outputs.bastion_security_group_id
  ]

  # Attach SSM IAM instance profile (also enables Session Manager)
  iam_instance_profile = data.terraform_remote_state.iam.outputs.ssm_ansible_instance_profile_name

  # User data for initial boot configuration
  user_data = templatefile("${path.module}/user-data-bastion.sh", {
    instance_name = "bastion"
  })

  # Tags for SSM targeting and identification
  tags = {
    Name        = "ssm-ansible-bastion"
    Role        = "bastion"
    Environment = var.environment
    Management  = "true"
    ManagedBy   = "SSM-Ansible"
  }

  # Ensure graceful replacement
  lifecycle {
    create_before_destroy = true
  }
}
