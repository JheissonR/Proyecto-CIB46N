resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
  tags = { Name = "migraiac-vpc-s04" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "migraiac-subnet-s04" }
}
