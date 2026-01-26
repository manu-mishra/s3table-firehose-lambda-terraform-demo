# Error Bucket
resource "aws_s3_bucket" "error_bucket" {
  bucket        = "${var.stack_name}-errors"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "error_bucket" {
  bucket = aws_s3_bucket.error_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Tables
resource "aws_s3tables_table_bucket" "table_bucket" {
  name = var.stack_name

  encryption_configuration = var.enable_encryption ? {
    sse_algorithm = "aws:kms"
    kms_key_arn   = aws_kms_key.s3_key[0].arn
  } : null
}

resource "aws_s3tables_namespace" "namespace" {
  namespace        = var.stack_name
  table_bucket_arn = aws_s3tables_table_bucket.table_bucket.arn
}

resource "aws_s3tables_table" "table" {
  name             = var.stack_name
  namespace        = aws_s3tables_namespace.namespace.namespace
  table_bucket_arn = aws_s3tables_table_bucket.table_bucket.arn
  format           = "ICEBERG"

  metadata {
    iceberg {
      schema {
        field {
          name     = "sensor_id"
          type     = "string"
          required = false
        }
        field {
          name     = "timestamp"
          type     = "long"
          required = false
        }
        field {
          name     = "location"
          type     = "string"
          required = false
        }
        field {
          name     = "temperature"
          type     = "double"
          required = false
        }
        field {
          name     = "humidity"
          type     = "double"
          required = false
        }
        field {
          name     = "pressure"
          type     = "double"
          required = false
        }
      }
    }
  }
}
