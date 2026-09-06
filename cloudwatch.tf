resource "aws_cloudwatch_dashboard" "imds" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "IMDSv1 calls - MetadataNoToken"
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/EC2",
              "MetadataNoToken",
              "InstanceId",
              aws_instance.lab.id
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Rejected IMDSv1 calls - MetadataNoTokenRejected"
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/EC2",
              "MetadataNoTokenRejected",
              "InstanceId",
              aws_instance.lab.id
            ]
          ]
        }
      }
    ]
  })
}
