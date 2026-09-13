terraform {
  backend "s3" {
    bucket = "terraform-state"
    key = "k8s-cluster/terraform.tfstate"
    region = "main"
    endpoints = { s3 = "http://192.168.1.125:9000" }
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_region_validation = true
    skip_requesting_account_id  = true
    use_path_style = true
  }

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint = var.pm_api_url
  insecure = true
}

module "k8s_nodes" {
  source = "git::https://github.com/skni-kod/terraform-modules.git//proxmox-vm?ref=v1.0.0"
  count = length(var.k8s_nodes)

  # Base configuration
  name = var.k8s_nodes[count.index].name
  target_node = var.target_node
  vmid = var.k8s_nodes[count.index].vmid
  
  # Assign tags
  tags = length(regexall("master", var.k8s_nodes[count.index].name)) > 0 ? [ "k8s_cluster", "k8s_master" ] : [ "k8s_cluster", "k8s_worker" ]

  cores = var.k8s_nodes[count.index].cores
  memory = var.k8s_nodes[count.index].mem

  # Disk
  disk_size = var.k8s_nodes[count.index].disk_size

  # Clone
  cloned_vm_id = 9000

  # Network
  network_bridge = var.network_bridge
  ip_address = var.k8s_nodes[count.index].ip
  gateway = var.gateway

  # OS config
  ci_user = var.ci_user
  ssh_public_key = var.ssh_public_key
}
