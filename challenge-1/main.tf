#############################################################
#                                                           #
#                      Project Credentials                  #
#                                                           #
#############################################################
variable "GOOGLE_APPLICATION_CREDENTIALS" {}
variable "DB_HOST" {}
variable "DB_PASS" {}

#############################################################
#                                                           #
#                     TF state file bucket                  #
#                                                           #
#############################################################
terraform {
  backend "gcs" {
    bucket = "new-terraform-tfstate"
    prefix = "terraform"
  }
}
#############################################################
#                                                           #
#                            Provider                       #
#                                                           #
#############################################################
provider "google" {
  credentials = var.GOOGLE_APPLICATION_CREDENTIALS
  project     = "ananta-demo"
  region      = "us-west1"
}
provider "google-beta" {
  credentials = var.GOOGLE_APPLICATION_CREDENTIALS
  project     = "ananta-demo"
  region      = "us-west1"
}
#############################################################
#                                                           #
#                     Local variables                       #
#                                                           #
#############################################################
locals {
  project = "ananta-demo"
  region  = "us-west1"
}
#############################################################
#                                                           #
#                         Enable APIs                       #
#                                                           #
#############################################################

resource "google_project_service" "enable_apis" {
  project = local.project
  service = ["cloudresourcemanager.googleapis.com", "compute.googleapis.com", "sqladmin.googleapis.com", "servicenetworking.googleapis.com"]
}

#############################################################
#                                                           #
#             IAM members and Policy assign                 #
#                                                           #
#############################################################

resource "google_project_iam_member" "iam_member" {
  project = local.project
  role    = "roles/editor"
  member  = "iamanantadas.info@gmail.com"
}


#############################################################
#                                                           #
#                       Service accounts                    #
#                                                           #
#############################################################

resource "google_service_account" "service_account" {
  account_id   = "sa-three-tier-apps"
  display_name = "sa-three-tier-apps"
  description  = "This service account is for creating a 3 tear application"
}


#############################################################
#                                                           #
#                        Resources                          #
#                                                           #
#############################################################

######################### migs and lbs ####################

module "web_mig" {
  source         = "./modules/migs-lbs"
  project        = "ananta-demo"
  target_size    = 2
  group1_region  = "us-west1"
  group2_region  = "us-east1"
  network_prefix = "multi-mig-lb-http"
}

module "app_mig" {
  source             = "./modules/migs-lbs"
  project            = "ananta-demo"
  region             = local.region
  network            = "demo-network2"
  subnetwork         = "demo-subnet2"
  service_account    = google_service_account.service_account.email
  subnetwork_project = "ananta-demo"
}

######################### SQL ####################
module "cloudsql_instance" {
  source           = "./modules/cloud-sql"
  db_instance_name = "demo-db-instance"
  db_version       = "MYSQL_5_7"
  database_project = local.project
  region           = local.region
  tier             = "db-n1-standard-2"
}

module "master_db" {
  source        = "./modules/cloud-sql"
  database_name = "demo-app-db"
}

module "db_users" {
  source    = "./modules/cloud-sql"
  user_name = "root"
  db_host   = var.DB_HOST
  db_pass   = var.DB_PASS
}