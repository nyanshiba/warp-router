#!/bin/bash

server=warp.igo
if [ "$1" == "" ]; then
  daemons="nftables warp-svc warp-mtu"
else
  daemons=$@
fi

rsync -rtv \
  --exclude='.git/' \
  --include='*/' \
  --include='sysctl.d/***' \
  --include='sysconfig/nftables.conf' \
  --include='systemd/network/***' \
  --include='systemd/system/***' \
  --exclude='*' \
  . "$server:/etc/"

ssh -t $server "systemctl daemon-reload; systemctl restart $daemons; sleep 0.5; echo $daemons: \$(systemctl is-active $daemons); nft list table nat; warp-cli tunnel stats"
