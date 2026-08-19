output "pipeline_bucket_name" {
  value       = aws_s3_bucket.pipeline_bucket.bucket
  description = "The name of the S3 bucket used for deployment artifacts."
}