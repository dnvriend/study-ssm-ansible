# 300-compute - Compute Layer
#
# Data sources for dependent layers and AMI lookup

# Data source for Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Remote state data source for 100-network layer
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "${path.module}/../100-network/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

# Remote state data source for 200-iam layer
data "terraform_remote_state" "iam" {
  backend = "local"
  config = {
    path = "${path.module}/../200-iam/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}
