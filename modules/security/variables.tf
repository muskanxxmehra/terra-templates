variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 5000
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

