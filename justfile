all: build-terraform

check-vars:
  #! /usr/bin/env -S bash
  if [[ -z "$DIGITALOCEAN_ACCESS_TOKEN" ]]; then
    echo "\$DIGITALOCEAN_ACCESS_TOKEN is not set." >&2
    echo "Please set it in `.envrc` and run `direnv reload`" >&2
    exit 1
  fi

  if [[ -z "$TAILSCALE_API_KEY" ]]; then
    echo "\$TAILSCALE_API_KEY is not set." >&2
    echo "Please set it in `.envrc` and run `direnv reload`" >&2
    exit 1
  fi

  if [[ -z "$TF_VAR_ts_api_key" ]]; then
    echo "\$TF_VAR_ts_api_key is not set." >&2
    echo "Please set it in `.envrc` and run `direnv reload`" >&2
    exit 1
  fi

build: check-vars build-packer build-terraform

[working-directory: 'packer']
build-packer:
  packer build config.pkr.hcl

[working-directory: 'terraform']
build-terraform:
  tofu destroy -auto-approve
  tofu apply -auto-approve
