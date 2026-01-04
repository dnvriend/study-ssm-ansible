# 600-dns - DNS Layer

This layer provisions DNS and SSL/TLS infrastructure.

## Resources Created

- Route53 hosted zone (optional)
- ACM certificate with DNS validation
- DNS alias records for ALB

## Dependencies

- **300-compute**: ALB DNS name and zone ID

## Usage

```bash
make layer-init LAYER=600-dns ENV=dev
make layer-plan LAYER=600-dns ENV=dev
make layer-apply LAYER=600-dns ENV=dev
```

## Configuration

Set `domain_name` in tfvars to enable DNS features:

```hcl
domain_name        = "example.com"
create_hosted_zone = true
create_certificate = true
create_alb_record  = true
alb_subdomain      = "api"  # Creates api.example.com
```

## Notes

- If using an existing hosted zone, set `existing_hosted_zone_id`
- ACM certificates require DNS validation via Route53
