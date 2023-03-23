variable "environment_suffix" {
  type = string
  description = "Procure le suffixe indiquant l'environnement cible"
}

variable "project_name" {
  type = string
}

variable "port" {
  type = number
}

variable "db_database" {
  type = string
}

variable "db_dialect" {
  type = string
}

variable "db_port" {
  type = number
}

variable "access-token-expiry" {
  type = string
}

variable "refresh-token-expiry" {
  type = string
}

variable "refresh-token-cookie-name" {
  type = string
}