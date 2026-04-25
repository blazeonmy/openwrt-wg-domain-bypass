#!/bin/sh
set -eu

echo "== OpenWrt release =="
cat /etc/openwrt_release 2>/dev/null || true

echo
echo "== Policy rules =="
ip rule show

echo
echo "== Bypass route table =="
ip route show table 100 || true

echo
echo "== nftables bypass set =="
nft list set inet fw4 wan_bypass || {
  echo "wan_bypass set not found"
  exit 1
}

echo
echo "== dnsmasq nftset runtime rules =="
grep -h -- '--nftset' /var/etc/dnsmasq.conf.* 2>/dev/null || {
  echo "No dnsmasq --nftset rules found"
  exit 1
}

echo
echo "Router state check completed."
