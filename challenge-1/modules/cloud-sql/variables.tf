variable "db_instance_name" {
  type = string
}

variable "db_version" {
  type = string
}

variable "region" {
  type = string
}

variable "tier" {
  type = string
}

variable "database_project" {
  type = string
}

variable public_ip {
  type    = bool
  default = false
}

variable "database_name" {
  type = string
}

variable "user_name" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_pass" {
  type = string
}