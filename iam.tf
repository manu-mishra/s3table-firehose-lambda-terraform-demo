# Firehose IAM Role
resource "aws_iam_role" "firehose_role" {
  name = "${var.stack_name}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "${var.stack_name}-firehose-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "S3TableAccessViaGlueFederation"
        Effect = "Allow"
        Action = ["glue:GetTable", "glue:GetDatabase", "glue:UpdateTable"]
        Resource = [
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog/s3tablescatalog/*",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog/s3tablescatalog",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/*/*"
        ]
      },
      {
        Sid    = "S3DeliveryErrorBucketPermission"
        Effect = "Allow"
        Action = ["s3:AbortMultipartUpload", "s3:GetBucketLocation", "s3:GetObject", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:PutObject"]
        Resource = [
          aws_s3_bucket.error_bucket.arn,
          "${aws_s3_bucket.error_bucket.arn}/*",
          aws_s3tables_table_bucket.table_bucket.arn,
          "${aws_s3tables_table_bucket.table_bucket.arn}/*"
        ]
      },
      {
        Sid      = "RequiredWhenDoingMetadataReadsANDDataAndMetadataWriteViaLakeformation"
        Effect   = "Allow"
        Action   = ["lakeformation:GetDataAccess"]
        Resource = "*"
      }],
      var.enable_encryption ? [{
        Sid    = "RequiredWhenUsingKMSEncryptionForS3ErrorBucketDelivery"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.s3_key[0].arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${var.region}.amazonaws.com"
          }
          StringLike = {
            "kms:EncryptionContext:aws:s3:arn" = [
              "${aws_s3_bucket.error_bucket.arn}/*",
              "${aws_s3tables_table_bucket.table_bucket.arn}/*"
            ]
          }
        }
      }] : []
    )
  })
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.stack_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.stack_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
        Effect   = "Allow"
        Resource = aws_kinesis_firehose_delivery_stream.main.arn
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}
