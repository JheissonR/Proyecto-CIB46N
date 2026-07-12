resource "aws_vpc" "main" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "migraiac-vpc-c06" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.3.0/24"
  availability_zone = "us-east-1c"
}

resource "aws_iam_role" "cluster" {
  name = "migraiac-eks-cluster-c06"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "eks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node" {
  name = "migraiac-eks-node-c06"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_cluster" "main" {
  name     = "migraiac-eks-c06"
  role_arn = aws_iam_role.cluster.arn
  vpc_config {
    subnet_ids = [aws_subnet.a.id, aws_subnet.b.id, aws_subnet.c.id]
  }
}

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "general-c06"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [aws_subnet.a.id, aws_subnet.b.id]
  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }
}

resource "aws_eks_node_group" "compute" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "compute-c06"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [aws_subnet.c.id]
  instance_types  = ["t3.large"]
  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 0
  }
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}

resource "aws_ecr_repository" "app" {
  name = "migraiac-app-c06"
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/migraiac-c06/cluster"
  retention_in_days = 7
}
