# Copyright 2024 - 2026 Dave Hall, Skwashd Services https://gata.works, MIT License

module "workflow_finetune_general" {
  source = "./modules/model-workflow"

  bucket_data_arn  = module.s3["data"].bucket_arn
  bucket_data_name = module.s3["data"].bucket_name

  bucket_model_arn  = module.s3["model"].bucket_arn
  bucket_model_name = module.s3["model"].bucket_name

  finetune_image_arn = module.ecr["finetune"].repo_arn
  finetune_image_url = module.ecr["finetune"].repo_url
  finetune_max_exec  = var.finetune_max_exec

  inference_image_arn = module.ecr["inference"].repo_arn
  inference_image_url = module.ecr["inference"].repo_url

  kms_key_arn = aws_kms_key.this.arn

  log_retention_days = var.log_retention_days

  model_namespace = "${var.application_name}-general"

  role_namespace            = var.role_namespace
  role_permissions_boundary = local.permissions_boundary

  ssm_image_path = local.ssm_image_path

  train_on_spot = var.train_on_spot

  tags = var.tags
}

module "workflow_finetune_low_volume" {
  source = "./modules/model-workflow"

  bucket_data_arn  = module.s3["data"].bucket_arn
  bucket_data_name = module.s3["data"].bucket_name

  bucket_model_arn  = module.s3["model"].bucket_arn
  bucket_model_name = module.s3["model"].bucket_name

  finetune_image_arn = module.ecr["finetune"].repo_arn
  finetune_image_url = module.ecr["finetune"].repo_url
  finetune_max_exec  = var.finetune_max_exec

  inference_image_arn = module.ecr["inference"].repo_arn
  inference_image_url = module.ecr["inference"].repo_url

  kms_key_arn = aws_kms_key.this.arn

  log_retention_days = var.log_retention_days

  model_namespace = "${var.application_name}-low-vol"

  role_namespace            = var.role_namespace
  role_permissions_boundary = local.permissions_boundary

  ssm_image_path = local.ssm_image_path

  train_on_spot = var.train_on_spot

  tags = var.tags
}

module "finetune_workflow" {
  source = "./modules/finetune-workflow"

  application_name = var.application_name

  db_cluster_arn = module.db.cluster_arn
  db_secret_arn  = module.db.secrets["user"]

  ecr_repo_arns   = { for module, props in module.ecr : module => props.repo_arn }
  ecr_repo_urls   = { for module, props in module.ecr : module => props.repo_url }
  ecs_cluster_arn = aws_ecs_cluster.this.arn

  event_bus_name = module.eventbus_gata.bus.name

  kms_key_arn = aws_kms_key.this.arn

  low_volume_fallback_label = var.low_volume_fallback_label

  role_namespace            = var.role_namespace
  role_permissions_boundary = local.permissions_boundary

  s3_bucket_name = module.s3["data"].bucket_name

  ssm_image_path = local.ssm_image_path

  sfn_arns = {
    general    = module.workflow_finetune_general.sfn_arn
    low_volume = module.workflow_finetune_low_volume.sfn_arn
  }

  subnet_ids = var.subnet_ids

  tags = var.tags

  vpc_endpoint_security_groups = var.vpc_endpoints
}
