output "cloudfront_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "origin" {
  value = module.bucket.this_bucket
}