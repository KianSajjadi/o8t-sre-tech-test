variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "provisioned_concurrency_executions" {
  description = "Number of provisioned concurrent executions for the Lambda function"
  type        = number
  default     = 5
}