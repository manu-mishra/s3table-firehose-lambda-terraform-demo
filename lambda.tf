data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/data_generator.py"
  output_path = "${path.module}/lambda/data_generator.zip"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.stack_name}-data-generator"
  retention_in_days = 1
  skip_destroy      = false
}

resource "aws_lambda_function" "data_generator" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.stack_name}-data-generator"
  role             = aws_iam_role.lambda_role.arn
  handler          = "data_generator.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.13"
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      STREAM_NAME = var.stack_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role_policy.lambda_policy
  ]
}

# EventBridge
resource "aws_cloudwatch_event_rule" "every_minute" {
  name                = "${var.stack_name}-every-minute"
  description         = "Trigger Lambda every minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_minute.name
  target_id = "lambda"
  arn       = aws_lambda_function.data_generator.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_minute.arn
}
