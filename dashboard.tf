# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.stack_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ==================== SECTION: Data Ingestion ====================
      {
        type   = "text"
        width  = 24
        height = 1
        x      = 0
        y      = 0
        properties = {
          markdown = "## 📥 Data Ingestion - Lambda Data Generator\nMonitors the Lambda function that generates IoT sensor data every minute (~10,000 records/invocation)"
        }
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
          title   = "Invocations"
          period  = 60
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 8
        height = 5
        x      = 0
        y      = 1
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
          title   = "Errors"
          period  = 60
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 8
        height = 5
        x      = 8
        y      = 1
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
          title   = "Duration (ms)"
          period  = 60
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 8
        height = 5
        x      = 16
        y      = 1
      },

      # ==================== SECTION: Streaming Delivery ====================
      {
        type   = "text"
        width  = 24
        height = 1
        x      = 0
        y      = 6
        properties = {
          markdown = "## 🚀 Streaming Delivery - Kinesis Data Firehose\nBuffers data (5 min or 5 MB) and delivers to S3 Tables in Apache Iceberg format"
        }
      },
      # Firehose - Incoming Records
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Firehose", "IncomingRecords", "DeliveryStreamName", var.stack_name, { stat = "Sum" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Incoming Records"
          period  = 60
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 12
        height = 5
        x      = 0
        y      = 7
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
          title   = "Delivery Success (green) / Failure (red)"
          period  = 60
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 12
        height = 5
        x      = 12
        y      = 7
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
          title   = "Data Freshness (seconds from ingestion to delivery)"
          period  = 60
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 12
        height = 5
        x      = 0
        y      = 12
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
          title   = "Bytes Delivered to S3 Tables"
          period  = 60
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 12
        height = 5
        x      = 12
        y      = 12
      },

      # ==================== SECTION: S3 Tables Storage ====================
      {
        type   = "text"
        width  = 24
        height = 1
        x      = 0
        y      = 17
        properties = {
          markdown = "## 🗄️ S3 Tables Storage - Apache Iceberg\nAnalytics-optimized storage with automatic table maintenance and compaction"
        }
      },
      # S3 Tables - Storage Size
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3/Tables", "TableBucketSizeBytes", "TableBucketName", var.stack_name, "TableName", "ALL", "StorageType", "TablesStandardStorage", "Namespace", "ALL"]
          ]
          view    = "singleValue"
          region  = var.region
          title   = "Total Storage Size (Bytes)"
          stacked = false
        }
        width  = 12
        height = 3
        x      = 0
        y      = 18
      },
      # S3 Tables - Object Count
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3/Tables", "TableBucketNumberOfObjects", "TableBucketName", var.stack_name, "TableName", "ALL", "StorageType", "ALL", "Namespace", "ALL"]
          ]
          view    = "singleValue"
          region  = var.region
          title   = "Total Number of Objects"
          stacked = false
        }
        width  = 12
        height = 3
        x      = 12
        y      = 18
      },
      # S3 Tables - Compaction Activity
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3/Tables", "CompactionObjectsCount_binpack", "TableBucketName", var.stack_name, "TableName", var.stack_name, "MaintenanceActivityType", "Compaction", "Namespace", var.stack_name, { id = "m1" }],
            [".", "CompactionBytesProcessed_binpack", ".", ".", ".", ".", ".", ".", ".", ".", { id = "m2" }]
          ]
          view      = "singleValue"
          region    = var.region
          title     = "Automatic Compaction - Objects & Bytes Processed"
          stat      = "Average"
          stacked   = false
          sparkline = true
        }
        width  = 24
        height = 3
        x      = 0
        y      = 21
      },

      # ==================== SECTION: Error Monitoring ====================
      {
        type   = "text"
        width  = 24
        height = 1
        x      = 0
        y      = 24
        properties = {
          markdown = "## ⚠️ Error Monitoring - Failed Deliveries\nTracks failed records sent to error bucket. Empty = healthy pipeline!"
        }
      },
      # Error Bucket - Storage Size
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", "${var.stack_name}-errors", "StorageType", "StandardStorage", { stat = "Average" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Error Bucket Size (Bytes)"
          period  = 86400
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 12
        height = 5
        x      = 0
        y      = 25
      },
      # Error Bucket - Object Count
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", "${var.stack_name}-errors", "StorageType", "AllStorageTypes", { stat = "Average" }]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Error Bucket Object Count"
          period  = 86400
          stacked = false
          yAxis   = { left = { min = 0 } }
        }
        width  = 12
        height = 5
        x      = 12
        y      = 25
      }
    ]
  })
}
