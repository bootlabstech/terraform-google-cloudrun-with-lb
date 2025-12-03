variable "cloudrun_name" {
  description = "The name of the cloudrun service"
  type        = string
}
variable "cloudrun_location" {
  description = "The location of the cloudrun service"
  type        = string
}
variable "project" {
  description = "The project of the cloudrun service"
  type        = string
}
variable "cloudrun_image" {
  description = "The image for the cloudrun service"
  type        = string
}

variable "cloudrun_cpu" {
  description = "Amt of cpu for the cloudrun - service "
  type        = string
  default     = "1000m"
}
variable "cloudrun_memory" {
  description = "Amt of memory for the cloudrun - service"
  type        = string
  default     = "512M"
}

variable "max_scale" {
  description = "No. of parallel srvs to which scaling is done"
  type        = string
}
variable "egress_traffic" {
  description = "Allowed egress for the connector.Can be either of private-ranges-only and all-traffic."
  type        = string
  default = "private-ranges-only"
}

variable "vpc_connector_self_link" {
  type        = string
  description = "The self link of host project vpc connector"
}

variable "existing_ssl_name" {
  type        = string
  description = "Name of existing SSL certificate in GCP"
}
variable "load_balancing_scheme" {
  type        = string
  description = "Type of load balancing scheme for the Global LB (EXTERNAL or INTERNAL)."
  default     = "EXTERNAL"
}

variable "backend_protocol" {
  type        = string
  description = "Protocol used by the backend service."
  default     = "HTTP"
}

variable "backend_timeout" {
  type        = number
  description = "Timeout (in seconds) for backend service requests."
  default     = 30
}

variable "global_fw_portrange" {
  type        = number
  description = "Port used by the global forwarding rule."
  default     = 443
}

variable "global_fw_ipprotocol" {
  type        = string
  description = "IP protocol used by the global forwarding rule."
  default     = "TCP"
}
variable "ingress" {
  type        = string
  description = "Controls Cloud Run ingress: choose All, Internal, or internal-and-cloud-load-balancing to allow traffic only from internal networks and external HTTPS load balancers."
  default     = "internal-and-cloud-load-balancing"
}
