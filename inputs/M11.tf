resource "aws_vpc" "main" {
  cidr_block = "10.5.0.0/16"
  tags       = { Name = "migraiac-vpc-m11" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.5.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.5.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_iam_role" "cluster" {
  name = "migraiac-eks-cluster-m11"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "eks.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "node" {
  name = "migraiac-eks-node-m11"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_eks_cluster" "main" {
  name     = "migraiac-eks-m11"
  role_arn = aws_iam_role.cluster.arn
  vpc_config {
    subnet_ids = [aws_subnet.a.id, aws_subnet.b.id]
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "migraiac-nodes-m11"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [aws_subnet.a.id, aws_subnet.b.id]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}
