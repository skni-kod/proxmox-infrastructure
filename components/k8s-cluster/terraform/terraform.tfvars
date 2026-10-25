network_bridge = "vmbr4"
gateway        = "10.20.1.1"
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoBqQY4eo8NTnzpebr0pCy1wZR7wWZ3G8jaIMYIFZdu sknikodprz@gmail.com"

k8s_nodes = {
  "k8s-master-1" = {
    ip        = "10.20.1.5/24"
    vmid      = 401
    mem       = 4096
    cores     = 2
    disk_size = 30
  },
  "k8s-worker-1" = {
    ip        = "10.20.1.6/24"
    vmid      = 402
    mem       = 4096
    cores     = 2
    disk_size = 30
  },
  "k8s-worker-2" = {
    ip        = "10.20.1.7/24"
    vmid      = 403
    mem       = 4096
    cores     = 2
    disk_size = 30
  }
}
