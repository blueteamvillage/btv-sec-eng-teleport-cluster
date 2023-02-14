/*
Configuration of S3 bucket for certs and replay
storage. Uses server side encryption to secure
session replays and SSL certificates.
*/

// S3 bucket for cluster storage
// For demo purposes, don't need bucket logging
// tfsec:ignore:aws-s3-enable-bucket-logging

resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_s3_bucket_public_access_block" "teleport" {
  bucket = aws_s3_bucket.teleport.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "teleport" {
  bucket = aws_s3_bucket.teleport.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "teleport" {
  # Enable server-side encryption by default
  bucket = aws_s3_bucket.teleport.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "teleport" {
  bucket = aws_s3_bucket.teleport.bucket
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "teleport" {
  bucket = aws_s3_bucket.teleport.bucket

  rule {
    id = "log"

    expiration {
      days = 90
    }

    filter {
      and {
        prefix = "records/"

        tags = {
          rule      = "log"
          autoclean = "true"
        }
      }
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket" "teleport" {
  bucket        = replace(lower("${var.PROJECT_PREFIX}-teleport-${random_string.bucket_suffix.result}"), "_", "-")
  force_destroy = true

  tags = {
    Project = var.PROJECT_PREFIX
  }
}
