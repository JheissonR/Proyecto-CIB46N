resource "aws_ec2_transit_gateway" "main" {
  description = "migraiac-tgw-c13"
}

resource "aws_vpc" "prod" {
  cidr_block = "10.30.0.0/16"
  tags       = { Name = "migraiac-prod-c13" }
}

resource "aws_vpc" "dev" {
  cidr_block = "10.31.0.0/16"
  tags       = { Name = "migraiac-dev-c13" }
}

resource "aws_vpc" "shared" {
  cidr_block = "10.32.0.0/16"
  tags       = { Name = "migraiac-shared-c13" }
}

resource "aws_subnet" "prod_a" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.30.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "dev_a" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.31.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "shared_a" {
  vpc_id            = aws_vpc.shared.id
  cidr_block        = "10.32.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.prod.id
  subnet_ids         = [aws_subnet.prod_a.id]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.dev.id
  subnet_ids         = [aws_subnet.dev_a.id]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.shared.id
  subnet_ids         = [aws_subnet.shared_a.id]
}

resource "aws_customer_gateway" "onprem" {
  bgp_asn    = 65000
  ip_address = "203.0.113.1"
  type       = "ipsec.1"
}

resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.shared.id
}

resource "aws_vpn_connection" "onprem" {
  customer_gateway_id = aws_customer_gateway.onprem.id
  vpn_gateway_id      = aws_vpn_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
}

resource "aws_flow_log" "prod" {
  vpc_id          = aws_vpc.prod.id
  traffic_type    = "ALL"
  log_destination = aws_s3_bucket.flowlogs.arn
  log_destination_type = "s3"
}

resource "aws_s3_bucket" "flowlogs" {
  bucket = "migraiac-flowlogs-c13"
}
