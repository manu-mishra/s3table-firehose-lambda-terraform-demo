# Firehose
resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = var.stack_name
  destination = "iceberg"

  iceberg_configuration {
    role_arn    = aws_iam_role.firehose_role.arn
    catalog_arn = "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog/s3tablescatalog/${var.stack_name}"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = aws_s3_bucket.error_bucket.arn
      prefix             = "errors/"
      buffering_size     = 5
      buffering_interval = 300
    }

    destination_table_configuration {
      database_name = var.stack_name
      table_name    = var.stack_name
    }
  }

  depends_on = [
    null_resource.post_foundation
  ]
}
