# Copyright 2024, 2025 Dave Hall, Skwashd Services https://gata.works, MIT License

data "aws_caller_identity" "current" {}

data "aws_kms_key" "gata" {
  key_id = var.kms_key_arn
}

# The count hack allows us to do the initial setup before the image is pushed
data "aws_ssm_parameter" "image_ref" {
  count = var.image_tag == null ? 1 : 0

  name = var.image_tag_param_name
}

data "aws_ecr_image" "this" {
  count = var.image_tag == null ? 1 : 0

  repository_name = aws_ecr_repository.this.name

  image_tag    = substr(data.aws_ssm_parameter.image_ref[0].value, 0, 1) == ":" ? substr(data.aws_ssm_parameter.image_ref[0].value, 1) : null
  image_digest = substr(data.aws_ssm_parameter.image_ref[0].value, 0, 1) == "@" ? substr(data.aws_ssm_parameter.image_ref[0].value, 1) : null
}
