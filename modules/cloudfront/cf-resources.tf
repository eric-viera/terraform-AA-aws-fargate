module "bucket" {
  source          = "eric-viera/AA-fargate/aws//modules/s3-bucket"
  bucket_name     = "${var.environment}-origin"
  log_bucket_name = "${var.environment}-origin-access-log"
  force_destroy   = true
}

resource "aws_cloudfront_origin_access_identity" "OAI" {
  comment = module.bucket.this_bucket
}

resource "aws_s3_bucket_policy" "oai_policy" {
  bucket = module.bucket.this_bucket
  policy = data.aws_iam_policy_document.oai_policy_doc.json
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  aliases             = [var.name_prefix == "" ? "${var.project}-${var.environment}.${data.aws_route53_zone.selected.name}" : "${var.name_prefix}.${data.aws_route53_zone.selected.name}"]
  web_acl_id          = aws_wafv2_web_acl.cf_waf.arn

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

    dynamic "lambda_function_association" {
      for_each = var.lambda_arn != "" ? [1] : []
      content {
        event_type = var.event
        lambda_arn = var.lambda_arn
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
  name    = var.name_prefix == "" ? "${var.project}-${var.environment}.${data.aws_route53_zone.selected.name}" : "${var.name_prefix}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
  }
}

resource "aws_wafv2_web_acl" "cf_waf" {
  name        = "${var.project}-${var.environment}-waf"
  description = "Uses AWS managed rulesets."
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS_CommonRules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        excluded_rule {
          name = "NoUserAgent_HEADER"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = ["CN", "US", "TR", "BR", "IN", "MY", "ID", "RU", "DE", "UA", "ES"]
            /* As of march 2022, according to Cloudflare, the top 10 sources of DDoS attacks are:
              1.China
              2.U.S.
              3.Brazil
              4.India
              5.Malaysia
              6.Indonesia
              7.Russia
              8.Germany
              9.Ukraine
             10.Spain
            Source: https://www.govtech.com/security/here-are-the-top-10-countries-where-ddos-attacks-originate */
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-AWSCommonRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_BadInputsRules"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-AWSBadInputsRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_AdminProtectionRules"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-AWSAdminProtectionRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_IpReputationRules"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-AWSIpReputationRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_AnonymousIpRules"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-AWSAnonymousIpRules-metric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-waf-metric"
    sampled_requests_enabled   = true
  }
}
