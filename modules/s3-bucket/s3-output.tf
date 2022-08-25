output "this_bucket" {
  description = "Name of this S3 bucket."
  value       = aws_s3_bucket.content.id
}

output "log_bucket" {
  description = "Name of the S3 bucket used for storing access logs of this bucket."
  value       = aws_s3_bucket.access_log.id
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.content.bucket_regional_domain_name
}

output "bucket_arn" {
  value = aws_s3_bucket.content.arn
}