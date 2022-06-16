resource "google_sql_database_instance" "master" {
  name             = var.db_instance_name
  database_version = var.db_version
  region           = "${var.region}"
  project = var.database_project
  settings {
    tier = var.tier
    ip_configuration {
      ipv4_enabled    = var.public_ip
      private_network = data.google_compute_network.vpc.self_link #var.vpc_link # the VPC where the db will be assigned a private IP
    }
  }
}
resource "google_sql_database" "database" {
  name      = var.database_name
  instance  = "${google_sql_database_instance.master.name}"
  charset   = "utf8"
  collation = "utf8_general_ci"
}
resource "google_sql_user" "users" {
  name     = var.user_name
  instance = "${google_sql_database_instance.master.name}"
  host     = var.db_host
  password = var.db_pass
}