resource "aws_vpc" "main" {
  cidr_block = "10.5.0.0/16"
  tags       = { Name = "migraiac-vpc-c14" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.5.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.5.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "batch" {
  name   = "migraiac-batch-c14"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "shared" {
  creation_token = "migraiac-efs-c14"
}

resource "aws_efs_mount_target" "a" {
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = aws_subnet.a.id
  security_groups = [aws_security_group.batch.id]
}

resource "aws_s3_bucket" "input" {
  bucket = "migraiac-batch-input-c14"
}

resource "aws_s3_bucket" "output" {
  bucket = "migraiac-batch-output-c14"
}

resource "aws_ecr_repository" "job" {
  name = "migraiac-job-c14"
}

resource "aws_iam_role" "batch_service" {
  name = "migraiac-batch-service-c14"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "batch.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "batch_execution" {
  name = "migraiac-batch-execution-c14"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_batch_compute_environment" "main" {
  compute_environment_name = "migraiac-compute-c14"
  type                     = "MANAGED"
  service_role             = aws_iam_role.batch_service.arn
  compute_resources {
    type               = "FARGATE"
    max_vcpus          = 16
    subnets            = [aws_subnet.a.id, aws_subnet.b.id]
    security_group_ids = [aws_security_group.batch.id]
  }
}

resource "aws_batch_job_queue" "main" {
  name     = "migraiac-queue-c14"
  state    = "ENABLED"
  priority = 1
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.main.arn
  }
}

resource "aws_batch_job_definition" "main" {
  name = "migraiac-job-c14"
  type = "container"
  platform_capabilities = ["FARGATE"]
  container_properties = jsonencode({
    image      = "${aws_ecr_repository.job.repository_url}:latest"
    resourceRequirements = [
      { type = "VCPU", value = "1" },
      { type = "MEMORY", value = "2048" }
    ]
    executionRoleArn = aws_iam_role.batch_execution.arn
  })
}

resource "aws_cloudwatch_log_group" "batch" {
  name              = "/aws/batch/migraiac-c14"
  retention_in_days = 7
}

resource "aws_sns_topic" "job_status" {
  name = "migraiac-job-status-c14"
}
