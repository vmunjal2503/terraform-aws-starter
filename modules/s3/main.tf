# ──────────────────────────────────────────────────────────
# S3 Module — Encrypted storage with versioning
# Creates: S3 Bucket, Versioning, Encryption, Lifecycle,
#          Public Access Block
# ──────────────────────────────────────────────────────────

resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-storage-${random_id.suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}-storage"
  }
}

# Random suffix to ensure bucket name uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# ──────────────── Versioning ────────────────
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ──────────────── Encryption ────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ──────────────── Block Public Access ────────────────
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────── Lifecycle Rules ────────────────
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  # Move old versions to cheaper storage after 30 days
  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    # Delete old versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # Clean up incomplete multipart uploads
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
