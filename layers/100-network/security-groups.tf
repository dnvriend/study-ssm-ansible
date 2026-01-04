# 100-network - Security Groups
#
# Security groups for web, app, and bastion hosts

# Web Security Group
resource "aws_security_group" "web" {
  name        = "${var.environment}-ssm-ansible-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-ssm-ansible-web-sg"
      Role = "web"
    }
  )
}

# Web Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from internet"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from internet"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id            = aws_security_group.web.id
  description                  = "SSH from bastion host"
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion.id
  tags                         = local.common_tags
}

# Web Egress Rule
resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

# App Security Group
resource "aws_security_group" "app" {
  name        = "${var.environment}-ssm-ansible-app-sg"
  description = "Security group for app servers"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-ssm-ansible-app-sg"
      Role = "app"
    }
  )
}

# App Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "app_flask" {
  security_group_id            = aws_security_group.app.id
  description                  = "Flask from web servers"
  from_port                    = 5000
  ip_protocol                  = "tcp"
  to_port                      = 5000
  referenced_security_group_id = aws_security_group.web.id
  tags                         = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh" {
  security_group_id            = aws_security_group.app.id
  description                  = "SSH from bastion host"
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion.id
  tags                         = local.common_tags
}

# App Egress Rule
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

# Bastion Security Group
resource "aws_security_group" "bastion" {
  name        = "${var.environment}-ssm-ansible-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-ssm-ansible-bastion-sg"
      Role = "bastion"
    }
  )
}

# Bastion Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  description       = "SSH from allowed CIDRs"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  cidr_ipv4         = var.allowed_ssh_cidrs[0]
  security_group_id = aws_security_group.bastion.id
  tags              = local.common_tags
}

# Bastion Egress Rule
resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}
