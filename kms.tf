# KMS Key
resource "aws_kms_key" "s3_key" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for ${var.stack_name} S3 bucket and S3 Tables encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions for Key Management"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = ["kms:*"]
        Resource = "*"
      },
      {
        Sid    = "Allow Firehose Role to Use Key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.firehose_role.arn
        }
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Tables Maintenance Service"
        Effect = "Allow"
        Principal = {
          Service = "maintenance.s3tables.amazonaws.com"
        }
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = "*"
      },
      {
        Sid    = "Allow Athena and Glue Services"
        Effect = "Allow"
        Principal = {
          Service = ["athena.amazonaws.com", "glue.amazonaws.com"]
        }
        Action   = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "s3_key_alias" {
  count         = var.enable_encryption ? 1 : 0
  name          = "alias/${var.stack_name}-s3-key"
  target_key_id = aws_kms_key.s3_key[0].key_id
}
