# Production environment configuration
enable_sample_lambda    = true
lambda_runtime          = "python3.12"
lambda_memory_size      = 256
lambda_timeout          = 60
enable_vpc_lambda       = true
enable_api_gateway      = true
enable_scheduled_lambda = false
schedule_expression     = "rate(1 hour)"
