
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  access_key = "XXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXX"
}

resource "aws_s3_bucket" "bucket_arquivos" {
  bucket = "bucket-fiap-2025"
}

resource "aws_sqs_queue" "fila_envio" {
  name = "sqs-fiap-2025"
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.fila_envio.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.fila_envio.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.bucket_arquivos.arn
          }
        }
      }
    ]
  })
}




resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket_arquivos.id

  queue {
    queue_arn = aws_sqs_queue.fila_envio.arn
    events    = ["s3:ObjectCreated:*"]
    filter_suffix = ".mpeg"
  }
}