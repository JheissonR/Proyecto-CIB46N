resource "aws_vpc" "main" {
  cidr_block = "10.2.0.0/16"
  tags = { Name = "migraiac-vpc-s09" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "migraiac-igw-s09" }
}
