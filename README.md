# OpenWrt WireGuard Domain Bypass

OpenWrt configuration template for a hybrid routing setup:

- default LAN internet traffic goes through WireGuard;
- selected domains and TLD zones are resolved by dnsmasq and added to an
  nftables set;
- traffic to addresses from that set is marked by fw4/nftables;
- marked packets are routed directly through WAN using a separate policy
  routing table.

The repository provides reusable templates and operational notes that can be
adapted to a local OpenWrt installation.

## Tested Platform

- OpenWrt 23.05.x
- WireGuard
- `dnsmasq-full`
- fw4 / nftables
- built-in `ip rule` and custom routing table

The setup does not require `pbr` or `vpn-policy-routing`.

## Architecture

```text
LAN client
  |
  | DNS query
  v
OpenWrt dnsmasq
  |
  | matching domains are resolved and inserted into nft set
  v
nft set: inet fw4 wan_bypass
  |
  | packets to matching destinations get fwmark
  v
ip rule fwmark -> table 100
  |
  | marked traffic exits via WAN
  v
ISP WAN

All unmarked traffic continues through WireGuard.
```

## Repository Layout

```text
.
|-- configs/
|   |-- network.example   # sanitized /etc/config/network snippets
|   |-- firewall.example  # sanitized /etc/config/firewall snippets
|   `-- dhcp.example      # sanitized /etc/config/dhcp snippets
|-- scripts/
|   `-- check-router-state.sh
`-- .github/workflows/ci.yml
```

## How It Works

### Network Layer

WireGuard is configured as the default route for LAN internet access. A
separate route keeps the WireGuard endpoint reachable through normal WAN so
the tunnel can establish correctly.

Marked packets use a separate routing table, `100`, where the default route
points to the WAN gateway.

### Firewall Layer

fw4/nftables keeps a set named `wan_bypass`. When LAN traffic targets an IP
address in that set, the packet receives mark `0x100`.

### DNS Layer

`dnsmasq-full` resolves configured domains and inserts their returned IP
addresses into the nftables set. This keeps the bypass dynamic when services
change IP addresses.

The configuration uses UCI `config ipset` sections because that format is
handled reliably by the OpenWrt dnsmasq init flow while still generating
runtime `--nftset` rules.

## Domain Zones

The example contains bypass entries for:

- selected service domains;
- `ru`;
- `su`;
- `xn--p1ai`, the punycode representation of the `.рф` zone.

## Apply Manually

Review the templates first:

```sh
vi configs/network.example
vi configs/firewall.example
vi configs/dhcp.example
```

Copy only the relevant snippets into:

```text
/etc/config/network
/etc/config/firewall
/etc/config/dhcp
```

Then reload services:

```sh
/etc/init.d/network reload
/etc/init.d/firewall reload
/etc/init.d/dnsmasq restart
```

## Verify

Run:

```sh
./scripts/check-router-state.sh
```

Useful manual checks:

```sh
ip rule show
ip route show table 100
nft list set inet fw4 wan_bypass
```

Resolve a matching domain from a LAN client and then check whether the set is
being populated.

## Limitations

- Domain-oriented, not ASN/GeoIP-oriented.
- Applications using DNS-over-HTTPS or private DNS may bypass router DNS and
  therefore skip automatic nft set population.
- CDN or third-party domains may need additional rules.
- The template is IPv4-oriented.
