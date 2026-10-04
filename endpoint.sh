#!/bin/bash

server=warp.igo
if [ "$1" == "" ]; then
  endpoint="reset"
else
  endpoint="set [2606:4700:100::a29f:c${1}0$2]:2408"
fi

ssh -t $server "warp-cli tunnel endpoint $endpoint; sleep 5; warp-cli tunnel stats"
