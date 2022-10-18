data "aws_iam_policy_document" "access_log_policy" {
  statement {
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.access_log.arn,
      "${aws_s3_bucket.access_log.arn}/*"
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

data "aws_iam_policy_document" "topic_policy_document" {
  statement {
    sid = "content"
    actions   = ["SNS:Publish"]
    effect    = "Allow"
    resources = ["arn:aws:sns:*:*:${aws_s3_bucket.content.id}-notification-topic" ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.content.arn]
    }
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
  statement {
    sid = "access-log"
    actions   = ["SNS:Publish"]
    effect    = "Allow"
    resources = ["arn:aws:sns:*:*:${aws_s3_bucket.access_log.id}-notification-topic"]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.access_log.arn]
    }
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
