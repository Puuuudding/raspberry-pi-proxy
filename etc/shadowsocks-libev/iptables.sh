#!/bin/bash

# Create new chain
iptables -t nat -N SHADOWSOCKS
iptables -t mangle -N SHADOWSOCKS

# Ignore your shadowsocks server's addresses
# It's very IMPORTANT, just be careful.
iptables -t nat -A SHADOWSOCKS -d <server_ip> -j RETURN
iptables -t mangle -A SHADOWSOCKS -d <server_ip> -j RETURN

# Ignore LANs and any other addresses you'd like to bypass the proxy
# See Wikipedia and RFC5735 for full list of reserved networks.
# See ashi009/bestroutetb for a highly optimized CHN route list.
#iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
for ip in $(cat /etc/shadowsocks-libev/localips); do
  iptables -t nat -A SHADOWSOCKS -d $ip -j RETURN
  iptables -t mangle -A SHADOWSOCKS -d $ip -j RETURN
done

# Anything else should be redirected to shadowsocks's local port
iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports 1080

# Add any UDP rules
#ip route add local default dev lo table 100
#ip rule add fwmark 1 lookup 100
#iptables -t mangle -A SHADOWSOCKS -p udp --dport 53 -j TPROXY --on-port 1080 --tproxy-mark 0x01/0x01
ip rule add fwmark 0x01/0x01 table 100
ip route add local 0.0.0.0/0 dev lo table 100
iptables -t mangle -A SHADOWSOCKS -p udp -j TPROXY --on-port 1080 --tproxy-mark 0x01/0x01

# Apply the rules
iptables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS
iptables -t mangle -A PREROUTING -j SHADOWSOCKS
