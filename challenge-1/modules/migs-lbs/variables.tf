variable "project" {
  type = string
}

variable "target_size" {
  type    = number
  default = 2
}

variable "group1_region" {
  type    = string
  default = "us-west1"
}

variable "group2_region" {
  type    = string
  default = "us-east1"
}

variable "network_prefix" {
  type    = string
  default = "multi-mig-lb-http"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "network" {
  type    = string
  default = "demo-network2"
}

variable "subnetwork" {
  type    = string
  default = "demo-subnet2"
}

variable "service_account" {
  type = object({
    email  = string
    scopes = set(string)
  })
}

variable "subnetwork_project" {
  type = string
}