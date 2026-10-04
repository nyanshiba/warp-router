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
# to use non-HTTP protocol like Discord, Minecraft etc.
dnf install nftables

# to use OSPF dynamic routing
dnf install frr

# to use RA RIOs routing
dnf install radvd

# to use ./update.sh
dnf install openssh-server rsync 
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
  - `frr.conf` : Automatically advertise IPv4 routes for AS13335. It also excludes `100.64.0.0/12` to use [Workers VPC](https://developers.cloudflare.com/workers-vpc/configuration/vpc-networks/#runtime-usage).  
    > In Exclude mode, the CGNAT range (100.64.0.0/10) is excluded from Cloudflare by default. Remove the CGNAT range from your exclude list so that Mesh IP traffic routes through Cloudflare.  
    [Connect client devices to Cloudflare Mesh · Cloudflare One docs](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-mesh/client-devices/#split-tunnel-configuration)
- **sysconfig/**
  - `nftables.conf` : Add IPv6 and non-HTTP protocol (e.g. Discord ICE) support using SNAT.  
    A DSCP value where the precedence in the IPv6 traffic class field is 5 (same as NGN SSE) and the remaining bits allow it to be distinguished from DSCP 0. Example:
    ```python
    # allow SSE (dscp 46)
    ipv6 access-list bri-out-sse deny icmp src any dest any tc 10
    
    # allow SSE(46) or warp-router(45)
    ipv6 access-list bri02-out-sse64 deny ip src any dest ff02::/96 precedence 0
    
    # allow ND proxy(5)
    ipv6 access-list bri1-out-ndp deny ip src any dest 8000::/1 precedence 5
    
    # allow SSE(46) and client(0)
    ipv6 access-list bri8d-out-sse64 deny ip src fe80::ffff/128 dest ff00::/8
    ```
- **sysctl.d/**
  - `forwarder.conf` : Enable IP & IPv6 forwarding.  
    To enable IPv6, you must switch from WireGuard to MASQUE. Additionally, similar to Workers VPC, you need to exclude return packets (internally `ip -6 route replace table 65743`) destined for the GUA in the Cloudflare One dashboard under Team & Resources > Devices > Device profiles.
- **systemd/**
  - **network/**
  - **eth0.network.d/**
      - `stable.conf` : Enable IPv6 privacy extensions to prevent tunnel address leaks.
  - **system/**  
    - `warp-mtu.service` : Optimize qdisc, increase MTU to 1340 (WireGuard) or 1304 (MASQUE) bytes, insert `nftables.conf`, and enabling IPv6 forwarding.
- `radvd.conf` : RA RIO routing configuration for IPv6 bridge environments (e.g., FLET'S Hikari RA mode. see [nyanshiba/nat64-on-link](https://github.com/nyanshiba/nat64-on-link)).
- `update.sh` : Update configuration files via rsync over SSH
