variable "pm_api_url" {
  description = "Proxmox API address"
  type        = string
}

variable "target_node" {
  description = "Aimed node in Proxmox"
  type        = string
}

variable "ci_user" {
  description = "User in k8s nodes"
  type        = string
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
  description = "List of VMs to deploy"
  type = list(object({
    name      = string
    ip        = string
    vmid      = number
    mem       = number
    cores     = number
    disk_size = number
  }))
}
