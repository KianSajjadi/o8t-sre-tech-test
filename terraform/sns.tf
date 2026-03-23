resource "aws_sns_topic" "alerts" {
  name = "metric-alarms"
}

resource "aws_sns_topic_subscription" "rotation_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.cloudwatch_email
}