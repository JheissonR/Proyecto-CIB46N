resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
  tags       = { Name = "migraiac-vpc-m03" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_db_subnet_group" "main" {
  name       = "migraiac-dbsubnet-m03"
  subnet_ids = [aws_subnet.a.id, aws_subnet.b.id]
}

resource "aws_security_group" "db" {
  name   = "migraiac-db-m03"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }
}

resource "aws_db_instance" "main" {
  identifier             = "migraiac-db-m03"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "ChangeMe123!"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
}

resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.small"
  subnet_id     = aws_subnet.a.id
  tags          = { Name = "migraiac-app-m03" }
}
