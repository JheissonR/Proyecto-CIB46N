resource "aws_instance" "server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.small"
  tags = { Name = "migraiac-server-s07" }
}

resource "aws_ebs_volume" "extra" {
  availability_zone = "us-east-1a"
  size              = 30
  type              = "gp3"
}

resource "aws_volume_attachment" "attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.extra.id
  instance_id = aws_instance.server.id
}
