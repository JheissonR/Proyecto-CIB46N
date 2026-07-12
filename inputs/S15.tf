resource "aws_instance" "monitored" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  tags = { Name = "migraiac-monitored-s15" }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "migraiac-cpu-high-s15"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    InstanceId = aws_instance.monitored.id
  }
}
