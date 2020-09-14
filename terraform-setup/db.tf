resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "10.7"
  instance_class       = "db.t2.micro"
  identifier           = "serviandb"
  username             = var.db_user_name
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot = true
}

resource "aws_db_subnet_group" "default" {
  name       = "serviandb_subnet_group"
  subnet_ids = [aws_subnet.private.*.id[2],aws_subnet.private.*.id[3]]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_security_group" "db" {
  name        = "DB security group"
  vpc_id      = aws_vpc.eksvpc.id

  ingress {
    description = "Allow connection from VPC CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.eksvpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "dbendpoint" {
  value = aws_db_instance.default.address
}