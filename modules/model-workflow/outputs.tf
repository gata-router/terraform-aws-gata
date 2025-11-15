output "endpoint_arn" {
  description = "ARN of the SageMaker endpoint created by the workflow"
  value = provider::aws::arn_build(
    data.aws_partition.current.id,
    "sagemaker",
    data.aws_region.current.name,
    data.aws_caller_identity.current.account_id,
    "endpoint/${var.model_namespace}"
  )
}

output "sfn_arn" {
  description = "ARN of the model workflow Step Function"
  value       = aws_sfn_state_machine.model_pipeline.arn
}
