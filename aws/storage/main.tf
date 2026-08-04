terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------- BUCKETS ----------
resource "aws_s3_bucket" "main" {
  for_each = var.buckets
  bucket   = "${var.bucket_prefix}-${each.key}"

  tags = {
    Name        = "${var.bucket_prefix}-${each.key}"
    Environment = var.environment
    Purpose     = each.key
  }
}

resource "aws_s3_bucket_versioning" "main" {
  for_each = var.buckets
  bucket   = aws_s3_bucket.main[each.key].id

  versioning_configuration {
    status = each.value ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = var.buckets
  bucket   = aws_s3_bucket.main[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  for_each = var.buckets
  bucket   = aws_s3_bucket.main[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- LIFECYCLE RULES (logs bucket only) ----------
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.main["logs"].id

  rule {
    id     = "logs-lifecycle"
    status = "Enabled"

    transition {
      days          = var.logs_archive_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.logs_delete_days
    }
  }
}

# ---------- BUCKET POLICY (grant read access to the data bucket) ----------
data "aws_iam_policy_document" "data_read" {
  count = length(var.reader_arns) > 0 ? 1 : 0

  statement {
    sid       = "AllowReadAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.main["data"].arn,
      "${aws_s3_bucket.main["data"].arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = var.reader_arns
    }
  }
}

resource "aws_s3_bucket_policy" "data_read" {
  count  = length(var.reader_arns) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main["data"].id
  policy = data.aws_iam_policy_document.data_read[0].json
}
