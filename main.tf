resource "google_project_service" "vpcaccess-api" {
  project = var.project
  service = "vpcaccess.googleapis.com"
}

resource "google_cloud_run_service" "default" {
  name     = var.cloudrun_name
  location = var.cloudrun_location
  project  = var.project
  metadata {
    annotations = {
      "run.googleapis.com/ingress" = var.ingress
    }
  }
  template {
    metadata {
      annotations = {
        # Limit scale up to prevent any cost blow outs!
        "autoscaling.knative.dev/maxScale"        = var.max_scale
        "run.googleapis.com/vpc-access-connector" = var.vpc_connector_self_link
        "run.googleapis.com/vpc-access-egress"    = var.egress_traffic


      }
    }

    spec {
      containers {
        image = var.cloudrun_image
        resources {
          limits = {
            cpu    = var.cloudrun_cpu
            memory = var.cloudrun_memory
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [

    ]
  }
}

# Fetch existing SSL certificate automatically
data "google_compute_ssl_certificate" "existing_ssl" {
  name = var.existing_ssl_name
}

# Use the existing SSL certificate in Target HTTPS Proxy
resource "google_compute_target_https_proxy" "proxy" {
  name             = "${var.cloudrun_name}-proxy"
  url_map          = google_compute_url_map.urlmap.id
  ssl_certificates = [data.google_compute_ssl_certificate.existing_ssl.self_link]
}

# ----------------------------
# Serverless NEG
# ----------------------------
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "${var.cloudrun_name}-neg"
  region                = "${var.cloudrun_location}"
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_service.default.name
  }
  depends_on = [ google_cloud_run_service.default ]
}
### Cloud armour policy
resource "google_compute_security_policy" "policy" {
  name    = "${var.cloudrun_name}-cloud-policy"
  project = var.project

  # Default deny all
  rule {
    action      = "deny(403)"
    priority    = 2147483647
    description = "default rule"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  # Rule 1000 - Allow IP set 1
  rule {
    action   = "allow"
    preview  = false
    priority = 1000

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "103.21.244.0/22",
          "103.22.200.0/22",
          "103.31.4.0/22",
          "108.162.192.0/18",
          "141.101.64.0/18",
          "173.245.48.0/20",
          "188.114.96.0/20",
          "190.93.240.0/20",
          "197.234.240.0/22",
          "198.41.128.0/17",
        ]
      }
    }
  }

  # Rule 1001 - Allow IP set 2
  rule {
    action      = "allow"
    description = "rule 2"
    preview     = false
    priority    = 1001

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "104.16.0.0/13",
          "104.24.0.0/14",
          "131.0.72.0/22",
          "162.158.0.0/15",
          "172.64.0.0/13",
        ]
      }
    }
  }
}


# ----------------------------
# Backend Service
# ----------------------------
resource "google_compute_backend_service" "backend" {
  name                  = "${var.cloudrun_name}-backend"
  load_balancing_scheme = var.load_balancing_scheme
  protocol              = var.backend_protocol
  timeout_sec           = var.backend_timeout

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
  security_policy = google_compute_security_policy.policy.id
}

# ----------------------------
# URL Map
# ----------------------------
resource "google_compute_url_map" "urlmap" {
  name            = "${var.cloudrun_name}-urlmap"
  default_service = google_compute_backend_service.backend.id
}

# ----------------------------
# Global Forwarding Rule (443)
# ----------------------------
resource "google_compute_global_forwarding_rule" "fr" {
  name        = "${var.cloudrun_name}-fr-https"
  target      = google_compute_target_https_proxy.proxy.id
  port_range  = var.global_fw_portrange
  ip_protocol = var.global_fw_ipprotocol
}

