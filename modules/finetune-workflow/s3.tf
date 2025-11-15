# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

locals {
  s3_bucket_arn = provider::aws::arn_build("aws", "s3", "", "", var.s3_bucket_name)
}
