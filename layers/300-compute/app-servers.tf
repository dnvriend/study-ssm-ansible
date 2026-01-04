# 300-compute - Application Servers
#
# EC2 instances for application servers running Flask

resource "aws_instance" "app" {
  count         = var.app_server_count
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.app_instance_type

  # Distribute across public subnets using round-robin
  subnet_id = element(
    data.terraform_remote_state.network.outputs.public_subnet_ids,
    count.index
  )

  # Attach application server security group
  vpc_security_group_ids = [
    data.terraform_remote_state.network.outputs.app_security_group_id
  ]

  # Attach SSM IAM instance profile
  iam_instance_profile = data.terraform_remote_state.iam.outputs.ssm_ansible_instance_profile_name

  # User data for initial boot configuration
  user_data = templatefile("${path.module}/user-data-app.sh", {
    instance_name = "app-${count.index + 1}"
  })

  # Tags for SSM targeting and identification
  tags = {
    Name        = "ssm-ansible-app-${count.index + 1}"
    Role        = "app"
    Environment = var.environment
    Stack       = "demo"
    ManagedBy   = "SSM-Ansible"
    AZ          = element(["eu-central-1a", "eu-central-1b"], count.index)
  }

  # Ensure graceful replacement
  lifecycle {
    create_before_destroy = true
  }
}
