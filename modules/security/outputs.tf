output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}
