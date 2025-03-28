data "digitalocean_droplet_snapshot" "piho" {
  name_regex  = "^ts-piho"
  region      = "nyc1"
  most_recent = true
}


resource "digitalocean_droplet" "piho" {
  image = data.digitalocean_droplet_snapshot.piho.id
  name = "piho"
  region = "nyc1"
  size = "s-1vcpu-512mb-10gb"
  ssh_keys = [
    digitalocean_ssh_key.terraform.fingerprint,
    data.digitalocean_ssh_key.yubikey.fingerprint
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    timeout = "2m"
    private_key = tls_private_key.bootstrap_private_key.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo tailscale up --accept-dns=false '--auth-key=${tailscale_tailnet_key.ts_auth_key.key}'",
    ]
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "export PATH=$PATH:/usr/bin",
  #     "sudo tailscale set --ssh",
  #     "sudo tailscale set --advertise-exit-node",
  #   ]
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "export PATH=$PATH:/usr/bin",
  #     "pihole enable",
  #   ]
  # }
}

# resource "digitalocean_droplet" "mitm" {
#   image = "ubuntu-24-04-x64"
#   name = "mitm"
#   region = "nyc1"
#   size = "s-1vcpu-512mb-10gb"
#   ssh_keys = [
#     digitalocean_ssh_key.terraform.fingerprint,
#     data.digitalocean_ssh_key.yubikey.fingerprint
#   ]

#   connection {
#     host = self.ipv4_address
#     user = "root"
#     type = "ssh"
#     timeout = "2m"
#     private_key = tls_private_key.bootstrap_private_key.private_key_openssh
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "export PATH=$PATH:/usr/bin",
#       "sudo apt-get update -y",
#       <<-EOT
#         sudo DEBIAN_FRONTEND=noninteractive \
#         UCF_FORCE_CONFFOLD=1 \
#         UCF_FORCE_CONFDEF=1 \
#         apt -o Dpkg::Options::="--force-confdef" \
#         -o Dpkg::Options::="--force-confold" \
#         upgrade -y
#       EOT
#     ]
#   }

#   # TODO extract into docker image
#   provisioner "remote-exec" {
#     inline = [
#       "export PATH=$PATH:/usr/bin",
#       "sh -c 'curl -fsSL https://tailscale.com/install.sh | sh'",
#       <<-EOM
#         echo 'net.ipv4.ip_forward = 1' | \
#           sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | \
#             sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
#       EOM
#     ]
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "export PATH=$PATH:/usr/bin",
#       "sudo tailscale up --advertise-exit-node '--auth-key=${tailscale_tailnet_key.ts_auth_key.key}'",
#     ]
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "export PATH=$PATH:/usr/bin",
#       "sudo apt-get install -y mitmproxy",
#     ]
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "export PATH=$PATH:/usr/bin",
#       "sudo sysctl -w net.ipv4.ip_forward=1",
#       "sudo sysctl -w net.ipv6.conf.all.forwarding=1",
#     ]
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "export PATH=$PATH:/usr/bin",
#       "sudo iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 80 -j REDIRECT --to-port 8080",
#       "sudo iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 443 -j REDIRECT --to-port 8080",
#       "sudo ip6tables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 80 -j REDIRECT --to-port 8080",
#       "sudo ip6tables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 443 -j REDIRECT --to-port 8080",
#     ]
#   }

#   # provisioner "remote-exec" {
#   #   inline = [
#   #     "export PATH=$PATH:/usr/bin",
#   #     "sudo tailscale set --ssh",
#   #     "sudo tailscale set --advertise-exit-node",
#   #   ]
#   # }

#   # provisioner "remote-exec" {
#   #   inline = [
#   #     "mkdir /etc/pihole",
#   #   ]
#   # }

#   # provisioner "file" {
#   #   content = templatefile("../config/pihole_setupVars.conf.tftpl", {
#   #     ipv4 = ""
#   #     ipv6 = ""
#   #     dns1 = ""
#   #     dns2 = ""
#   #     dns3 = ""
#   #     dns4 = ""
#   #   })
#   #   destination = "/etc/pihole/setupVars.conf"
#   # }

#   # provisioner "remote-exec" {
#   #   inline = [
#   #     "export PATH=$PATH:/usr/bin",
#   #     "curl -L https://install.pi-hole.net | bash /dev/stdin --unattended",
#   #   ]
#   # }

#   # provisioner "remote-exec" {
#   #   inline = [
#   #     "export PATH=$PATH:/usr/bin",
#   #     "pihole setpassword password",
#   #   ]
#   # }
# }

resource "digitalocean_firewall" "web" {
  name = "piho"

  droplet_ids = [digitalocean_droplet.piho.id]

  inbound_rule {
    protocol         = "udp"
    port_range       = "3478"
    source_addresses = ["100.64.0.0/10"]
  }

  inbound_rule {
    protocol              = "udp"
    port_range            = "41641"
    source_addresses      = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

data "tailscale_devices" "pihos" {
  name_prefix = "piho"
  # wait_for = "60s"
  depends_on = [
    digitalocean_droplet.piho
  ]
}

resource "tailscale_dns_nameservers" "nameservers" {
  nameservers = flatten(data.tailscale_devices.pihos.devices[*].addresses)
}

# data "tailscale_device" "piho" {
#   name = "piho.finch-carp.ts.net"
#   wait_for = "60s"
#   depends_on = [
#     digitalocean_droplet.piho
#   ]
# }

#
# resource "tailscale_dns_nameservers" "nameservers" {
#   nameservers = data.tailscale_device.piho.addresses
# }
