variable "db_host" {}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
variable "db_port" {
  default = "5432"
}
variable "jwt_secret" {
  description = "Chave secreta usada para assinar tokens JWT"
  type        = string
}