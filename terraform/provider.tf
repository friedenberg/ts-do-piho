
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }

    tailscale = {
      source = "tailscale/tailscale"
      version = "0.18.0"
    }
  }
}

variable ts_api_key {}

provider "digitalocean" {
}

provider "tailscale" {
  # api_key = var.ts_api_key
}

resource "tls_private_key" "bootstrap_private_key" {
  algorithm = "ED25519"
}

resource "digitalocean_ssh_key" "terraform" {
  name = "terraform"
  public_key = tls_private_key.bootstrap_private_key.public_key_openssh
}

data "digitalocean_ssh_key" "yubikey" {
  name = "yubikey"
}

resource "tailscale_tailnet_key" "ts_auth_key" {
  reusable      = false
  ephemeral     = true
  preauthorized = true
}
