# warp-router
Configure the WARP connector (`warp-svc`) as a gateway to AS13335.

## Requirements

- A Linux server with Dual-stack (IPv4 and IPv6) support
- A router supporting OSPFv2 or static routing
- A Cloudflare account
    - Create a Connector in the Cloudflare One (formerly Zero Trust) dashboard and follow the installation instructions:
      [Cloudflare One Dashboard](https://dash.cloudflare.com/one) -> Networks -> Connectors
    - Add CIDR routes (e.g., `192.168.0.0/16`) in Networks -> Routes

## Installation

- Clone this repository and copy the files to your Linux server under the `/etc/` directory.
  The provided `./update.sh` script may be useful for this.
```sh
git clone https://github.com/nyanshiba/warp-router.git -o upstream --depth 1 
```
- On the Linux server, install `nftables`. If you are supporting OSPFv2, you should also install FRRouting (`frr`).
```sh
dnf install nftables #frr
```
- Enable the `warp-mtu` service to run on boot.
```sh
systemctl enable --now warp-mtu
```

## Customization Hints

**/etc/**
- `endpoint.sh` : Change to a specific WARP Connector endpoint for better performance
- **frr/**
  - `daemons` : Enable OSPFv2
  - `frr.conf` : Automatically advertise routes for AS13335.
- **sysconfig/**
  - `nftables.conf` : Add Discord ICE support using SNAT.
- **sysctl.d/**
  - `forwarder.conf` : Enable IP forwarding
- **systemd/**
  - **network/**
  - **eth0.network.d/**
      - `stable.conf` : Enable IPv6 privacy extensions to prevent tunnel address leaks.
  - **system/**  
    - `warp-mtu.service` : Optimize qdisc, increase MTU to 1340 bytes, and insert `nftables.conf`.
- `update.sh` : Update configuration files via rsync over SSH
