resource "aws_vpc" "main" {
  cidr_block = "10.4.0.0/16"
  tags       = { Name = "migraiac-vpc-c10" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.4.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.4.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.4.3.0/24"
  availability_zone = "us-east-1c"
}

resource "aws_db_subnet_group" "main" {
  name       = "migraiac-aurora-c10"
  subnet_ids = [aws_subnet.a.id, aws_subnet.b.id, aws_subnet.c.id]
}

resource "aws_security_group" "aurora" {
  name   = "migraiac-aurora-c10"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.4.0.0/16"]
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier     = "migraiac-aurora-c10"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.04.0"
  database_name          = "migraiac"
  master_username        = "admin"
  master_password        = "ChangeMe123456!"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.aurora.id]
  skip_final_snapshot    = true
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "migraiac-writer-c10"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
}

resource "aws_rds_cluster_instance" "reader_a" {
  identifier         = "migraiac-reader-a-c10"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
}

resource "aws_rds_cluster_instance" "reader_b" {
  identifier         = "migraiac-reader-b-c10"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
}

resource "aws_secretsmanager_secret" "db" {
  name = "migraiac-db-secret-c10"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({ username = "admin", password = "ChangeMe123456!" })
}

resource "aws_iam_role" "proxy" {
  name = "migraiac-proxy-c10"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "rds.amazonaws.com" } }]
  })
}

resource "aws_db_proxy" "main" {
  name                   = "migraiac-proxy-c10"
  engine_family          = "MYSQL"
  role_arn               = aws_iam_role.proxy.arn
  vpc_subnet_ids         = [aws_subnet.a.id, aws_subnet.b.id]
  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.db.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "migraiac-aurora-cpu-c10"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
}

resource "aws_sns_topic" "alerts" {
  name = "migraiac-aurora-alerts-c10"
}
