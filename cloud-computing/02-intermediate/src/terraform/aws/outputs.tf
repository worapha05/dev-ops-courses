output "alb_dns" {
  value = aws_lb.app.dns_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}
