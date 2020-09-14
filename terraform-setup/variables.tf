variable "aws_region" {
  type = string
}

variable "cluster-name" {
  default = "techchallenge-cluster"
  type    = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "db_user_name" {
  type = string
  description = "1 to 16 alphanumeric characters. First character must be a letter"
}

variable "db_password" {
  type = string
  description = "Constraints: At least 8 printable ASCII characters. Can't contain any of the following: / (slash), '(single quote), (double quote) and @ (at sign)."
}