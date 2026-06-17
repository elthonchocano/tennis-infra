resource "aws_security_group" "lambda_sg" {
  name        = "tennis-lambda-security-group"
  description = "Firewall rules for the Quarkus reactive Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "tennis-lambda-sg" }
}

resource "aws_security_group" "db_sg" {
  name        = "tennis-database-security-group"
  description = "Firewall rules for the PostgreSQL database instance"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL traffic from tennis-backend Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "tennis-database-sg" }
}
