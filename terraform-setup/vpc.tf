resource "aws_vpc" "eksvpc" {
  cidr_block = "10.0.0.0/16"

  tags = map(
    "Name", "eksvpc-techchallenge",
    "kubernetes.io/cluster/${var.cluster-name}", "shared"
  )
}

resource "aws_subnet" "public" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eksvpc.id

  tags = map(
    "Name", "publicsubnet",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
    "kubernetes.io/role/elb", "1"
  )
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.eksvpc.id
  tags = {
    Name = "eks-ig"
  }
}

resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.eksvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "public" {
  count = 2
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.publicRT.id
}

resource "aws_subnet" "private" {
  count = 4
  availability_zone       = data.aws_availability_zones.available.names[count.index%2]
  cidr_block              = "10.0.${count.index + 2}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eksvpc.id
  tags = map(
    "Name", "privatesubnet",
    "kubernetes.io/cluster/${var.cluster-name}", "shared"
  )
}

resource "aws_eip" "eip" {
  count = 2
  vpc   = true
}

resource "aws_nat_gateway" "nat" {
  count = 2
  allocation_id = aws_eip.eip.*.id[count.index]
  subnet_id     = aws_subnet.public.*.id[count.index]
}

resource "aws_route_table" "privateRT" {
  count = 2
  vpc_id = aws_vpc.eksvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.*.id[count.index]
  }
}

resource "aws_route_table_association" "private" {
  count = 4
  subnet_id      = aws_subnet.private.*.id[count.index]
  route_table_id = aws_route_table.privateRT.*.id[count.index%2]
}
