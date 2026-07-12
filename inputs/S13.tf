resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  tags = { Name = "migraiac-web-s13" }
}

resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"
}
