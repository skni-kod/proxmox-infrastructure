variable "pm_api_url" {
  description = "Proxmox API address"
  type        = string
  default     = "https://192.168.1.2:8006"
}

variable "target_node" {
  description = "Aimed node in Proxmox"
  type        = string
  default     = "malwina"
}

variable "ci_user" {
  description = "User in k8s nodes"
  type        = string
  default     = "skni-technical-user"
}

variable "ssh_public_key" {
  description = "SSH key"
  type        = string
}

variable "network_bridge" {
  description = "Selection of specific bridge"
  type        = string
}

variable "gateway" {
  description = "Network gateway for K8s nodes"
  type        = string
}

variable "k8s_nodes" {
  description = "Map of VMs to deploy"
  type = map(object({
    ip        = string
    vmid      = number
    mem       = number
    cores     = number
    disk_size = number
  }))
}
