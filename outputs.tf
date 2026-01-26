output "firehose_stream_name" {
  value = aws_kinesis_firehose_delivery_stream.main.name
}

output "firehose_stream_arn" {
  value = aws_kinesis_firehose_delivery_stream.main.arn
}

output "table_bucket_name" {
  value = aws_s3tables_table_bucket.table_bucket.name
}

output "table_bucket_arn" {
  value = aws_s3tables_table_bucket.table_bucket.arn
}

output "error_bucket_name" {
  value = aws_s3_bucket.error_bucket.bucket
}

output "glue_database_name" {
  value = var.stack_name
}

output "glue_table_name" {
  value = var.stack_name
}

output "lambda_function_name" {
  value = aws_lambda_function.data_generator.function_name
}

output "kms_key_arn" {
  value = var.enable_encryption ? aws_kms_key.s3_key[0].arn : null
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
  description = "CloudWatch Dashboard URL"
}
