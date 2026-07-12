resource "aws_vpc" "main" {
  cidr_block = "10.6.0.0/16"
  tags       = { Name = "migraiac-vpc-m14" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.6.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "migraiac-cache-subnet-m14"
  subnet_ids = [aws_subnet.a.id]
}

resource "aws_security_group" "cache" {
  name   = "migraiac-cache-m14"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.6.0.0/16"]
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "migraiac-redis-m14"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.cache.id]
}

resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.small"
  subnet_id     = aws_subnet.a.id
  tags          = { Name = "migraiac-app-m14" }
}
