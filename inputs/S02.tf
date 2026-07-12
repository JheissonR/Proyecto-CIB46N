resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  tags = {
    Name        = "migraiac-app-s02"
    Environment = "dev"
  }
}
