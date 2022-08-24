data "aws_acm_certificate" "certificate" {
  domain   = "*.${var.domain}"
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "selected" {
  name         = var.domain
  private_zone = false
}

data "aws_iam_policy_document" "oai_policy_doc" {
  statement {
    sid       = "CloudfrontOriginAccessIdentity"
    actions   = ["s3:GetObject"]
    resources = ["${module.bucket.bucket_arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.OAI.iam_arn]
    }
  }

  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      module.bucket.bucket_arn,
      "${module.bucket.bucket_arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

