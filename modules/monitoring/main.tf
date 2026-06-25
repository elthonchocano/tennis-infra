resource "aws_sns_topic" "api_alerts" {
  name = "tennis-api-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.api_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "api_high_traffic" {
  alarm_name          = "tennis-api-high-traffic-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "5000"
  alarm_description   = "High traffic alarm on API Gateway"
  alarm_actions       = [aws_sns_topic.api_alerts.arn]

  dimensions = {
    ApiId = var.api_id
  }
}
