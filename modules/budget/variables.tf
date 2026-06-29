variable "budget_limit" {
  description = "The monthly spending limit in USD"
  type        = number
}

variable "notification_email" {
  description = "The email address to receive budget alerts"
  type        = string
}
