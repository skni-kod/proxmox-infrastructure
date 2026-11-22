network_bridge = "vmbr1"
gateway        = "192.168.1.1"
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoBqQY4eo8NTnzpebr0pCy1wZR7wWZ3G8jaIMYIFZdu sknikodprz@gmail.com"

docker_nodes = {
  "docker-stag" = {
    ip        = "192.168.1.117/24"
    vmid      = 501
    mem       = 4096
    cores     = 2
    disk_size = 30
  },
}
