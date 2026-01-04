# Production environment configuration
enable_s3_bucket   = true
s3_versioning      = true
s3_lifecycle_days  = 60
enable_rds         = true
rds_instance_class = "db.t3.medium"
rds_multi_az       = true
