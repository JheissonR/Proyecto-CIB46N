resource "aws_vpc" "main" {
  cidr_block = "10.3.0.0/16"
  tags = { Name = "migraiac-vpc-s12" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "migraiac-rt-s12" }
}
