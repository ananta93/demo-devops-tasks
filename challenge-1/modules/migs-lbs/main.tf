resource "google_compute_network" "default" {
  name                    = var.network_prefix
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "group1" {
  name          = "${var.network_prefix}-group1"
  ip_cidr_range = "10.126.0.0/20"
  network       = google_compute_network.default.self_link
  region        = var.group1_region
}

resource "google_compute_router" "group1" {
  name    = "${var.network_prefix}-gw-group1"
  network = google_compute_network.default.self_link
  region  = var.group1_region
}

module "cloud-nat-group1" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.4.0"
  router     = google_compute_router.group1.name
  project_id = var.project
  region     = var.group1_region
  name       = "${var.network_prefix}-cloud-nat-group1"
}

resource "google_compute_subnetwork" "group2" {
  name          = "${var.network_prefix}-group2"
  ip_cidr_range = "10.127.0.0/20"
  network       = google_compute_network.default.self_link
  region        = var.group2_region
}

resource "google_compute_network" "demo-network2" {
  name                    = "${var.network}-vpc"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "private-subnet" {
  name                     = "${var.subnet}-private-subnet"
  ip_cidr_range            = "10.128.0.0/20"
  network                  = "${var.network}-vpc"
  depends_on               = ["google_compute_network.demo-network2"]
  region                   = var.region
  private_ip_google_access = true
}

resource "google_compute_router" "group2" {
  name    = "${var.network_prefix}-gw-group2"
  network = google_compute_network.default.self_link
  region  = var.group2_region
}

module "cloud-nat-group2" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.4.0"
  router     = google_compute_router.group2.name
  project_id = var.project
  region     = var.group2_region
  name       = "${var.network_prefix}-cloud-nat-group2"
}

module "gce-lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 5.1"
  name    = var.network_prefix
  project = var.project
  target_tags = [
    "${var.network_prefix}-group1",
    module.cloud-nat-group1.router_name,
    "${var.network_prefix}-group2",
    module.cloud-nat-group2.router_name
  ]
  firewall_networks = [google_compute_network.default.name]

  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false

      health_check = {
        check_interval_sec  = 10
        timeout_sec         = 5
        healthy_threshold   = 2
        unhealthy_threshold = 5
        request_path        = "/"
        port                = 80
        host                = null
        logging             = null
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group = module.mig1.instance_group
        },
        {
          group = module.mig2.instance_group
        },
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }
  }
}
# [END cloudloadbalancing_ext_http_gce]

####################### ILB ################
module "gce-ilb" {
  source       = "../../"
  project      = var.project
  region       = var.region
  name         = "group-ilb"
  ports        = [local.named_ports[0].port]
  source_tags  = module.gce-lb-http.target_tags
  target_tags  = ["allow-group2", "allow-group3"]
  health_check = local.health_check

  backends = [
    {
      group       = module.mig3.instance_group
      description = ""
      failover    = false
    },
    {
      group       = module.mig4.instance_group
      description = ""
      failover    = false
    },
  ]
}
