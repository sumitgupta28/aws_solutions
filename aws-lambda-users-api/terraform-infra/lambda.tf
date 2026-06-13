# Package the function code (lambda_function.py + models.py only — heavy deps
# live in the layer). The zip is rebuilt whenever either source file changes.
data "archive_file" "function" {
  type        = "zip"
  output_path = "${path.module}/.build/function.zip"

  source {
    content  = file("${path.module}/../lambda_function.py")
    filename = "lambda_function.py"
  }
  source {
    content  = file("${path.module}/../models.py")
    filename = "models.py"
  }
}

# Pre-built Pydantic layer (built for Amazon Linux per DEPLOY.md).
resource "aws_lambda_layer_version" "pydantic" {
  layer_name          = "${var.project_name}-pydantic"
  filename            = var.layer_zip_path
  source_code_hash    = filebase64sha256(var.layer_zip_path)
  compatible_runtimes = [var.lambda_runtime]
  description         = "pydantic + email-validator (Amazon Linux build)"
}

# Create the log group explicitly so retention is managed and the IAM policy
# can scope to it (instead of letting Lambda auto-create it).
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "users_api" {
  function_name = var.project_name
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = "lambda_function.lambda_handler"
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256

  layers = [aws_lambda_layer_version.pydantic.arn]

  environment {
    variables = {
      LOG_LEVEL = var.log_level
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logs,
    aws_cloudwatch_log_group.lambda,
  ]
}
