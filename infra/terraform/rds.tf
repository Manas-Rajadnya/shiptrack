data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["shiptrack-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = ["shiptrack-subnet-private*"]
  }
}

data "aws_security_group" "app" {
  filter {
    name   = "group-name"
    values = ["shiptrack-app-sg"]
  }
}

data "aws_ssm_parameter" "db_password" {
  name = "/shiptrack/dev/db_password"
}

resource "aws_db_subnet_group" "main" {
  name       = "shiptrack-db-subnet-group"
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    Name      = "shiptrack-db-subnet-group"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group" "db" {
  name        = "shiptrack-db-sg"
  description = "MySQL from the app security group only"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "MySQL from app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_security_group.app.id]
  }

  tags = {
    Name      = "shiptrack-db-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_db_instance" "main" {
  identifier             = "shiptrack-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = "shiptrack"
  username               = "shiptrackadmin"
  password               = data.aws_ssm_parameter.db_password.value
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true

  tags = {
    Name      = "shiptrack-db"
    ManagedBy = "terraform"
  }
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}