# Troubleshooting

## Bypass Set Stays Empty

Check whether dnsmasq generated nftset runtime rules:

```sh
grep -h -- '--nftset' /var/etc/dnsmasq.conf.*
```

If there is no output:

- confirm `dnsmasq-full` is installed;
- confirm the UCI sections use `config ipset`;
- restart dnsmasq with `/etc/init.d/dnsmasq restart`.

## Domains Resolve But Traffic Still Uses WireGuard

Check whether the destination IP entered the set:

```sh
nft list set inet fw4 wan_bypass
```

Then confirm the policy rule and route table:

```sh
ip rule show
ip route show table 100
```

The fwmark rule should point to table `100`, and table `100` should have a
default WAN route.

## WireGuard Does Not Come Up

Make sure the WireGuard peer endpoint itself has a host route through WAN.
Without that route, the router may try to reach the VPN endpoint through the
VPN tunnel before the tunnel exists.

## Some Page Assets Still Use VPN

Many sites load assets from separate CDN or API domains. Add those domains to
the dnsmasq bypass list if they must also use WAN.

## Private DNS Or DoH Clients Ignore The Bypass

The automatic bypass depends on the router seeing DNS queries. If clients use
private DNS, DNS-over-HTTPS, or hardcoded external resolvers, the router will
not know which domain was resolved.

Options:

- advertise the router as DNS through DHCP;
- block or redirect external DNS where appropriate;
- add explicit domains for known application endpoints.
