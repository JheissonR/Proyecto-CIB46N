resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
  tags       = { Name = "migraiac-vpc-c03" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name   = "migraiac-alb-c03"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "svc_a" {
  name = "migraiac-svc-a-c03"
}

resource "aws_ecr_repository" "svc_b" {
  name = "migraiac-svc-b-c03"
}

resource "aws_ecs_cluster" "main" {
  name = "migraiac-cluster-c03"
}

resource "aws_iam_role" "execution" {
  name = "migraiac-exec-c03"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_cloudwatch_log_group" "svc_a" {
  name              = "/ecs/migraiac-svc-a-c03"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "svc_b" {
  name              = "/ecs/migraiac-svc-b-c03"
  retention_in_days = 7
}

resource "aws_lb" "main" {
  name               = "migraiac-alb-c03"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "svc_a" {
  name        = "migraiac-tg-a-c03"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc_a.arn
  }
}

resource "aws_ecs_task_definition" "svc_a" {
  family                   = "migraiac-svc-a-c03"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{
    name  = "svc-a"
    image = "${aws_ecr_repository.svc_a.repository_url}:latest"
    portMappings = [{ containerPort = 80 }]
  }])
}

resource "aws_ecs_task_definition" "svc_b" {
  family                   = "migraiac-svc-b-c03"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{
    name  = "svc-b"
    image = "${aws_ecr_repository.svc_b.repository_url}:latest"
    portMappings = [{ containerPort = 8080 }]
  }])
}

resource "aws_ecs_service" "svc_a" {
  name            = "migraiac-svc-a-c03"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.svc_a.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.alb.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "svc_b" {
  name            = "migraiac-svc-b-c03"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.svc_b.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.alb.id]
    assign_public_ip = true
  }
}
