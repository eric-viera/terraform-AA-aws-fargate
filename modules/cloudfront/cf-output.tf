output "cloudfront_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "origin" {
  value = module.bucket.this_bucket
}

output "fqdn" {
  value = aws_route53_record.dns.fqdn
}
