variable "project_id" {
  description = "project id"
  type        = string
  default     = ""
}

variable "nomad_cluster" {
  type = map(object({
    hostname         = string
    plan             = string
    facilities       = string
    operating_system = string
    billing_cycle    = string
  }))
}

variable "nomad_version" {
  description = "Version for the Nomad"
  type        = string
  default     = ""
}

variable "consul_version" {
  description = "Version for the Consul"
  type        = string
  default     = ""
}

variable "metal_token" {
  description = "metal token used for consul retry-join"
  type        = string
  default     = ""
}

// should correlate with the nomad_cluster map size
variable "cluster_size" {
  description = "size of the Nomad cluster"
  type        = number
  default     = 5
}
