resource "aws_vpc" "main" {
  cidr_block = "10.2.0.0/16"
  tags       = { Name = "migraiac-vpc-m05" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "app" {
  name   = "migraiac-app-m05"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "migraiac-lt-m05"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.app.id]
}

resource "aws_autoscaling_group" "app" {
  name                = "migraiac-asg-m05"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.a.id, aws_subnet.b.id]
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
