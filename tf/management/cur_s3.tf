resource "aws_s3_bucket" "cur" {
  bucket = format("%s-cur", var.unique_prefix)
  acl    = "private"
}

resource "aws_s3_bucket_policy" "cur" {
  bucket = aws_s3_bucket.cur.id
  policy = data.aws_iam_policy_document.cur.json
}

data "aws_iam_policy_document" "cur" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      format("%s/*", aws_s3_bucket.cur.arn)
    ]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy"
    ]
    resources = [
      aws_s3_bucket.cur.arn
    ]
  }

  statement {
    sid = "AllowSSLRequestsOnly"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.cur.arn,
      format("%s/*", aws_s3_bucket.cur.arn)
    ]
    condition {
      test     = "aws:SecureTransport"
      variable = "Bool"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_cur_report_definition" "cur_report_definition" {
  provider                   = aws.us-east-1 # Resource only support us-east-1 region
  report_name                = "Hourly-Cost-and-Usage-Report"
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.cur.id
  s3_region                  = var.BaseRegion
}

resource "aws_s3_bucket_public_access_block" "cur" {
  bucket                  = aws_s3_bucket.cur.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}