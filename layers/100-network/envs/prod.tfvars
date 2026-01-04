# Production environment configuration
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
enable_nat_gateway   = true
single_nat_gateway   = false
