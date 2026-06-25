variable "db_subnet_ids" {
  description = "List of private subnet IDs for the RDS instance"
  type        = list(string)
}

variable "db_security_group_ids" {
  description = "List of security group IDs for the RDS instance"
  type        = list(string)
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}
