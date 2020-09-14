resource "aws_secretsmanager_secret" "secret" {
  name = "dbcreds"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    dbuser = var.db_user_name
    dbpassword = var.db_password
    dbendpoint = aws_db_instance.default.address
  })
}