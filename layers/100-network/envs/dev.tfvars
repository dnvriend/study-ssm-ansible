# Development environment configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["eu-central-1a", "eu-central-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
enable_nat_gateway   = false
single_nat_gateway   = true
