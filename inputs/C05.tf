resource "aws_vpc" "app" {
  cidr_block = "10.10.0.0/16"
  tags       = { Name = "migraiac-app-vpc-c05" }
}

resource "aws_vpc" "data" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "migraiac-data-vpc-c05" }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
}

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "data_a" {
  vpc_id            = aws_vpc.data.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "data_b" {
  vpc_id            = aws_vpc.data.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_vpc_peering_connection" "app_to_data" {
  vpc_id      = aws_vpc.app.id
  peer_vpc_id = aws_vpc.data.id
  auto_accept = true
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.app.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }
  route {
    cidr_block                = "10.20.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.app_to_data.id
  }
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.data.id
  route {
    cidr_block                = "10.10.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.app_to_data.id
  }
}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "data_a" {
  subnet_id      = aws_subnet.data_a.id
  route_table_id = aws_route_table.data.id
}

resource "aws_route_table_association" "data_b" {
  subnet_id      = aws_subnet.data_b.id
  route_table_id = aws_route_table.data.id
}

resource "aws_security_group" "app" {
  name   = "migraiac-app-sg-c05"
  vpc_id = aws_vpc.app.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "data" {
  name   = "migraiac-data-sg-c05"
  vpc_id = aws_vpc.data.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }
}
