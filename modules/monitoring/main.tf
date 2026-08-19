resource "aws_sns_topic" "api_alerts" {
  name = "tennis-api-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.api_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_high_error_rate" {
  alarm_name          = "tennis-frontend-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "High 5xx error rate on CloudFront frontend distribution"
  alarm_actions       = [aws_sns_topic.api_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = var.cloudfront_id
    Region         = "Global"
  }
}