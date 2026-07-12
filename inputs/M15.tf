resource "aws_vpc" "main" {
  cidr_block = "10.7.0.0/16"
  tags       = { Name = "migraiac-vpc-m15" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.7.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.7.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_db_subnet_group" "main" {
  name       = "migraiac-db-subnet-m15"
  subnet_ids = [aws_subnet.a.id, aws_subnet.b.id]
}

resource "aws_db_instance" "main" {
  identifier           = "migraiac-pg-m15"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  username             = "admin"
  password             = "ChangeMe123!"
  db_subnet_group_name = aws_db_subnet_group.main.name
  multi_az             = true
  skip_final_snapshot  = true
}

resource "aws_sns_topic" "alerts" {
  name = "migraiac-alerts-m15"
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "migraiac-db-cpu-m15"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "storage" {
  alarm_name          = "migraiac-db-storage-m15"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }
}
