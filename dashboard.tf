# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.stack_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Firehose - Incoming Records
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Firehose", "IncomingRecords", "DeliveryStreamName", var.stack_name, { stat = "Sum" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Firehose - Incoming Records"
          period  = 60
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 0
      },
      # Firehose - Delivery Success/Failure
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Firehose", "DeliveryToIceberg.SuccessfulRowCount", "DeliveryStreamName", var.stack_name, { stat = "Sum", color = "#2ca02c" }],
            [".", "DeliveryToIceberg.FailedRowCount", ".", ".", { stat = "Sum", color = "#d62728" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Firehose - Delivery Success/Failure"
          period  = 60
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 0
      },
      # Firehose - Data Freshness
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Firehose", "DeliveryToIceberg.DataFreshness", "DeliveryStreamName", var.stack_name, { stat = "Average" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Firehose - Data Freshness (ms)"
          period  = 60
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 6
      },
      # Firehose - Bytes Delivered
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Firehose", "DeliveryToIceberg.Bytes", "DeliveryStreamName", var.stack_name, { stat = "Sum" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Firehose - Bytes Delivered"
          period  = 60
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 6
      },
      # Lambda - Invocations
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.stack_name}-data-generator", { stat = "Sum", color = "#1f77b4" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Lambda - Invocations"
          period  = 60
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 8
        height = 6
        x      = 0
        y      = 12
      },
      # Lambda - Errors
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "${var.stack_name}-data-generator", { stat = "Sum", color = "#d62728" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Lambda - Errors"
          period  = 60
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 8
        height = 6
        x      = 8
        y      = 12
      },
      # Lambda - Duration
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${var.stack_name}-data-generator", { stat = "Average" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Lambda - Duration (ms)"
          period  = 60
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 8
        height = 6
        x      = 16
        y      = 12
      },
      # S3 Tables - Storage Size
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3/Tables", "TotalBucketStorage", "TableBucketName", var.stack_name, "Namespace", var.stack_name, "TableName", var.stack_name, { stat = "Sum" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "S3 Tables - Storage Size (Bytes)"
          period  = 86400
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 18
      },
      # S3 Tables - File Count
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3/Tables", "TotalNumberOfFiles", "TableBucketName", var.stack_name, "Namespace", var.stack_name, "TableName", var.stack_name, { stat = "Sum" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "S3 Tables - File Count"
          period  = 86400
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 18
      }
    ]
  })
}
