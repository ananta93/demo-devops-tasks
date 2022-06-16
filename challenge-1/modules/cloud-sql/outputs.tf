output "connection" {
  value = google_sql_database_instance.master.connection_name
}

output "name" {
  description = "name of DB instance"
  value       = google_sql_database_instance.master.name
}

