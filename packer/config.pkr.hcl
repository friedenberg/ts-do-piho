source "digitalocean" "ts-piho" {
  image         = "ubuntu-24-10-x64"
  region        = "nyc1"
  size          = "s-1vcpu-512mb-10gb"
  ssh_username  = "root"
  snapshot_name = "ts-piho"
}

build {
  sources = ["source.digitalocean.ts-piho"]

  provisioner "shell" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      <<-EOT
        sudo DEBIAN_FRONTEND=noninteractive \
        UCF_FORCE_CONFFOLD=1 \
        UCF_FORCE_CONFDEF=1 \
        dpkg-reconfigure -plow unattended-upgrades
      EOT
    ]
  }

  provisioner "shell" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update -y",
      <<-EOT
        sudo DEBIAN_FRONTEND=noninteractive \
        UCF_FORCE_CONFFOLD=1 \
        UCF_FORCE_CONFDEF=1 \
        apt-get -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        upgrade -y
      EOT
    ]
  }

  provisioner "shell" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sh -c 'curl -fsSL https://tailscale.com/install.sh | sh'",
      # "sh -c 'echo \"net.ipv4.ip_forward = 1\" | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo \"net.ipv6.conf.all.forwarding = 1\" | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf'",
    ]
  }

  provisioner "shell" {
    inline = [
      "mkdir /etc/pihole",
    ]
  }

  // TODO make ip addresses variables
  provisioner "file" {
    content = templatefile("pihole_setupVars.conf.tftpl", {
      dns1 = "9.9.9.9"
      dns2 = "149.112.112.112"
      dns3 = ""
      dns4 = ""
    })
    destination = "/etc/pihole/setupVars.conf"
  }

  # restart required for pihole installation
  provisioner "shell" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo shutdown -r now",
    ]
  }

  provisioner "shell" {
    pause_before = "2m"
    inline = [
      "export PATH=$PATH:/usr/bin",
      # `|| pihole -r` is due to https://github.com/pi-hole/pi-hole/issues/6047
      # can probably remove when that's resolved mainline
      "curl -L https://install.pi-hole.net | bash /dev/stdin --unattended || pihole -r",
    ]
  }

  # provisioner "shell" {
  #   inline = [
  #     "export PATH=$PATH:/usr/bin",
  #     "pihole setpassword password",
  #   ]
  # }

  # provisioner "shell" {
  #   inline = [
  #     "export PATH=$PATH:/usr/bin",
  #     <<-EOT
  #     sed -i '' 's/listeningMode\s*=\s*"\w+"/listeningMode = "ALL"/' /etc/pihole/pihole.toml
  #     EOT
  #   ]
  # }
}

