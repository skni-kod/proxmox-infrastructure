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
  description = "User in docker nodes"
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
  description = "Network gateway for Docker nodes"
  type        = string
}

variable "cloned_vm_id" {
  description = "Template VMID to clone"
  type        = number
  default     = 9000
}

variable "docker_node" {
  description = "Single Docker VM definition"
  type = object({
    name      = string
    ip        = string
    vmid      = number
    mem       = number
    cores     = number
    disk_size = number
  })
}
