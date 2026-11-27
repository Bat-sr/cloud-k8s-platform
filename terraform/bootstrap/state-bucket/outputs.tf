output "bucket_name" {
  description = "Name of the state bucket"
  value       = aws_s3_bucket.state.id
}

output "backend_hcl" {
  description = "Put these lines into terraform/envs/aws-lab/backend.hcl"
  value       = "bucket = \"${aws_s3_bucket.state.id}\"\nregion = \"${var.region}\""
}
