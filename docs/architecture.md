# Architecture

This setup keeps WireGuard as the default route while allowing selected
destination domains to leave directly through WAN.

## Packet Flow

1. A LAN client sends a DNS query to the router.
2. `dnsmasq-full` resolves the domain.
3. If the domain matches a configured `ipset` rule, dnsmasq inserts the
   resolved IPv4 address into `inet fw4 wan_bypass`.
4. A LAN packet targeting that address reaches fw4/nftables.
5. The firewall marks the packet with `0x100`.
6. `ip rule` sends marked packets to routing table `100`.
7. Table `100` sends the packet through WAN.
8. Traffic without the mark continues through WireGuard.

## Components

| Layer | Component | Purpose |
|---|---|---|
| DNS | `dnsmasq-full` | Resolves domains and populates the nftables set |
| Firewall | fw4 / nftables | Matches destination IPs and applies fwmark |
| Routing | `ip rule` | Selects a routing table based on fwmark |
| Routing | table `100` | Sends bypassed traffic through WAN |
| VPN | WireGuard | Default route for all other traffic |

## Why dnsmasq `ipset` Sections

OpenWrt can render runtime dnsmasq nftset rules from UCI `config ipset`
sections. This keeps the runtime implementation on nftables while using a UCI
format that is widely supported by the dnsmasq init flow.

## Design Tradeoffs

- The design follows domain resolution, not GeoIP or ASN ownership.
- It is lightweight and does not depend on a separate policy-routing package.
- DNS-over-HTTPS clients may bypass the mechanism unless DNS is controlled at
  the network edge.
- IPv4 is the primary target. IPv6 can be added separately if the LAN uses it.
