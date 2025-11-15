# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0.0, < 3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}
