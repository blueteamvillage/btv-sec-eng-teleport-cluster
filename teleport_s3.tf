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

resource "aws_s3_bucket" "storage" {
  bucket        = "btv-terraform-s3-storage-${random_string.bucket_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "storage" {
  bucket = aws_s3_bucket.storage.bucket
  acl    = "private"
}

// For demo purposes, CMK is not needed
// tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
