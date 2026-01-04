# 700-lambda - Lambda Layer

This layer provisions serverless infrastructure.

## Resources Created

- Lambda function (sample)
- CloudWatch Log Groups
- API Gateway HTTP API (optional)
- EventBridge scheduled rules (optional)
- VPC configuration (optional)

## Dependencies

- **100-network**: VPC, subnets (for VPC Lambda)
- **200-iam**: Lambda execution role

## Usage

```bash
make layer-init LAYER=700-lambda ENV=dev
make layer-plan LAYER=700-lambda ENV=dev
make layer-apply LAYER=700-lambda ENV=dev
```

## Configuration

| Variable | Description |
|----------|-------------|
| enable_sample_lambda | Deploy sample Lambda function |
| enable_vpc_lambda | Deploy Lambda inside VPC |
| enable_api_gateway | Create API Gateway trigger |
| enable_scheduled_lambda | Create EventBridge schedule |

## API Gateway

When enabled, the API Gateway creates a `/hello` endpoint:
```
GET {api_gateway_url}/hello
```

## Notes

Replace the sample Lambda code with your actual function code.
