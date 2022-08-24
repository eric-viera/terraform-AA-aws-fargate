module "bucket" {
  source          = "../s3-website-bucket"
  bucket_name     = "${var.environment}-origin"
  log_bucket_name = "${var.environment}-origin-access-log"
  force_destroy   = true
  tags            = { project = var.project, environment = var.environment }
}

resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = module.bucket.this_bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "OAI" {
  comment = module.bucket.this_bucket
}

resource "aws_s3_bucket_policy" "oai_policy" {
  bucket = module.bucket.this_bucket
  policy = data.aws_iam_policy_document.oai_policy_doc.json
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled     = true
  price_class = "PriceClass_100"
  default_root_object = "index.html"
  aliases = [ "${var.project}-${var.environment}.${data.aws_route53_zone.selected.name}" ]
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = module.bucket.this_bucket

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = module.bucket.bucket_regional_domain_name
    origin_id   = module.bucket.this_bucket
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.OAI.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = data.aws_acm_certificate.certificate.arn
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_record" "dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.project}-${var.environment}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
  }
}