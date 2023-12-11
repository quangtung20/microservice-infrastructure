data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "db-creds"
}

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Security Group for MySQL Database"
  vpc_id      = var.fgms_vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Hãy chỉ cho phép truy cập từ các địa chỉ IP cụ thể thay vì 0.0.0.0/0 trong môi trường thực tế
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "database" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  db_name                = "sakila"
  username               = local.db_creds.username
  password               = local.db_creds.password
  db_subnet_group_name   = var.fgms_database_subnet_group
  vpc_security_group_ids = ["${aws_security_group.mysql_sg.id}"]
  skip_final_snapshot    = true
}

locals {
  parts = split(":", aws_db_instance.database.endpoint)
  host  = local.parts[0]
}
