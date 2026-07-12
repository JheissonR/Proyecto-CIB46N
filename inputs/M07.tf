resource "aws_ecr_repository" "app" {
  name = "migraiac-app-m07"
}

resource "aws_ecs_cluster" "main" {
  name = "migraiac-cluster-m07"
}

resource "aws_iam_role" "task" {
  name = "migraiac-task-m07"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/migraiac-m07"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = "migraiac-task-m07"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task.arn
  container_definitions = jsonencode([{
    name  = "app"
    image = "${aws_ecr_repository.app.repository_url}:latest"
    portMappings = [{ containerPort = 80 }]
  }])
}

resource "aws_ecs_service" "app" {
  name            = "migraiac-service-m07"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"
}
