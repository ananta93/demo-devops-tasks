data "template_file" "group-startup-script" {
  template = file(format("%s/gceme.sh.tpl", path.module))

  vars = {
    PROXY_PATH = ""
  }
}

module "mig1_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "6.2.0"
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group1.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix          = "${var.network_prefix}-group1"
  startup_script       = data.template_file.group-startup-script.rendered
  source_image_family  = "ubuntu-1804-lts"
  source_image_project = "ubuntu-os-cloud"
  tags = [
    "${var.network_prefix}-group1",
    module.cloud-nat-group1.router_name
  ]
}

module "mig1" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig1_template.self_link
  region            = var.group1_region
  hostname          = "${var.network_prefix}-group1"
  target_size       = var.target_size
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group1.self_link
}

module "mig2_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "6.2.0"
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group2.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = "${var.network_prefix}-group2"
  startup_script = data.template_file.group-startup-script.rendered
  tags = [
    "${var.network_prefix}-group2",
    module.cloud-nat-group2.router_name
  ]
}

module "mig2" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig2_template.self_link
  region            = var.group2_region
  hostname          = "${var.network_prefix}-group2"
  target_size       = var.target_size
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group2.self_link
}

#############################################################
#                                                           #
#                        Internal LB                        #
#                                                           #
#############################################################

##################### Internal migs and lbs #################
module "mig3_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  version            = "~> 6.2.0"
  project_id         = var.project
  subnetwork         = var.subnetwork
  subnetwork_project = var.subnetwork_project
  service_account    = var.service_account
  startup_script     = templatefile("${path.module}/gceme_ilb.sh.tpl", { PROXY_PATH = "" })
  tags               = ["allow-group2"]
}

module "mig4_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  version            = "~> 6.2.0"
  project_id         = var.project
  subnetwork         = var.subnetwork
  subnetwork_project = var.subnetwork_project
  service_account    = var.service_account
  startup_script     = templatefile("${path.module}/gceme_ilb.sh.tpl", { PROXY_PATH = "" })
  tags               = ["allow-group3"]
}

module "mig3" {
  source             = "terraform-google-modules/vm/google//modules/mig"
  version            = "~> 6.2.0"
  project_id         = var.project
  subnetwork_project = var.subnetwork_project
  region             = var.region
  hostname           = "mig3"
  instance_template  = module.mig3_template.self_link
  named_ports        = local.named_ports
}

module "mig4" {
  source             = "terraform-google-modules/vm/google//modules/mig"
  version            = "~> 6.2.0"
  project_id         = var.project
  subnetwork_project = var.subnetwork_project
  region             = var.region
  hostname           = "mig4"
  instance_template  = module.mig4_template.self_link
  named_ports        = local.named_ports
}
