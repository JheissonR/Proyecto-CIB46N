resource "aws_vpc" "main" {
  cidr_block           = "10.6.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "migraiac-vpc-c15" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.6.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.6.11.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.6.12.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
}

resource "aws_security_group" "app" {
  name   = "migraiac-app-c15"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "data" {
  name   = "migraiac-data-c15"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "migraiac-db-c15"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "main" {
  identifier             = "migraiac-db-c15"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.small"
  allocated_storage      = 50
  username               = "admin"
  password               = "ChangeMe123!"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.data.id]
  multi_az               = true
  skip_final_snapshot    = true
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "migraiac-cache-c15"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "migraiac-redis-c15"
  description          = "migraiac cache cluster"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 2
  engine               = "redis"
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.data.id]
}

resource "aws_iam_role" "eks_cluster" {
  name = "migraiac-eks-c15"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "eks.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "eks_node" {
  name = "migraiac-eks-node-c15"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_eks_cluster" "main" {
  name     = "migraiac-eks-c15"
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "migraiac-nodes-c15"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/eks/migraiac-c15"
  retention_in_days = 14
}

resource "aws_sns_topic" "alerts" {
  name = "migraiac-alerts-c15"
}

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "migraiac-db-cpu-c15"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
