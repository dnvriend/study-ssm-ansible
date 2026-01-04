# 300-compute - Web Servers
#
# EC2 instances for web servers running Nginx

resource "aws_instance" "web" {
  count         = var.web_server_count
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.web_instance_type

  # Distribute across public subnets using round-robin
  subnet_id = element(
    data.terraform_remote_state.network.outputs.public_subnet_ids,
    count.index
  )

  # Attach web server security group
  vpc_security_group_ids = [
    data.terraform_remote_state.network.outputs.web_security_group_id
  ]

  # Attach SSM IAM instance profile
  iam_instance_profile = data.terraform_remote_state.iam.outputs.ssm_ansible_instance_profile_name

  # User data for initial boot configuration
  user_data = templatefile("${path.module}/user-data-web.sh", {
    instance_name = "web-${count.index + 1}"
  })

  # Tags for SSM targeting and identification
  tags = {
    Name        = "ssm-ansible-web-${count.index + 1}"
    Role        = "web"
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
