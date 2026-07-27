variable "name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-dbsub"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name}-pg"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = "appdb"
  username                = var.username
  password                = var.password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.vpc_security_group_ids
  multi_az                = var.multi_az
  publicly_accessible     = false
  storage_encrypted       = true
  skip_final_snapshot     = true
  backup_retention_period = 7
  tags                    = var.tags
}

output "address" {
  value = aws_db_instance.this.address
}

output "arn" {
  value = aws_db_instance.this.arn
}
