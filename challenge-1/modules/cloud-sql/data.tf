data "google_compute_network" "vpc" {
  name    = "demo-network2-vpc"
  project = var.database_project
}
