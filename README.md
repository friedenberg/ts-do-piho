# description

bootstrap a tailscale connected and firewalled pihole

implemented with packer and terraform scripts that do the following:

- build a VM with pihole and tailscale installed on it
- save a snapshot to digital ocean
- create a droplet with that image and add it to tailscale
- set the tailscale DNS point to all the `piho*` prefixed devices

# usage

- populate `.env` with `$DIGITALOCEAN_ACCESS_TOKEN` and `$TAILSCALE_API_KEY`
- `direnv allow`
- `just`

# dependencies

- `nix`
- `direnv`


