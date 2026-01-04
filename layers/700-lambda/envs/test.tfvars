# Test environment configuration
enable_sample_lambda    = false
lambda_runtime          = "python3.12"
lambda_memory_size      = 128
lambda_timeout          = 30
enable_vpc_lambda       = false
enable_api_gateway      = false
enable_scheduled_lambda = false
schedule_expression     = "rate(1 hour)"
