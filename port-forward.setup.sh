#!/bin/bash

set -e

################################
# Variables
################################
proxy_port=7892
local_ipv4=$(/sbin/ip route | awk '/default/ { print $3 }')


################################
# Allow IP Forward (Temporary)
################################
echo 1 > /proc/sys/net/ipv4/ip_forward

################################
# Allow IP Forward (Permanent)
################################
#echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
#sysctl -p


################################
# Redir-Host with UDP
# See https://lancellc.gitbook.io/clash/start-clash/clash-udp-tproxy-support
################################

################
# TCP
################
iptables -t nat -N clash
iptables -t nat -A clash -d 0.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 10.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 127.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 169.254.0.0/16 -j RETURN
iptables -t nat -A clash -d 172.16.0.0/12 -j RETURN
iptables -t nat -A clash -d 192.168.0.0/16 -j RETURN
iptables -t nat -A clash -d 224.0.0.0/4 -j RETURN
iptables -t nat -A clash -d 240.0.0.0/4 -j RETURN
iptables -t nat -A clash -d "$local_ipv4" -j RETURN
iptables -t nat -A clash -p tcp -j REDIRECT --to-port "$proxy_port"
iptables -t nat -I PREROUTING -p tcp -d 8.8.8.8 -j REDIRECT --to-port "$proxy_port"
iptables -t nat -I PREROUTING -p tcp -d 8.8.4.4 -j REDIRECT --to-port "$proxy_port"
iptables -t nat -A PREROUTING -p tcp -j clash

################
# UDP (Clash UDP TProxy only supported in Linux and OpenWRT)
################
ip rule add fwmark 1 table 100
ip route add local default dev lo table 100
iptables -t mangle -N clash
iptables -t mangle -A clash -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A clash -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A clash -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A clash -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A clash -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A clash -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A clash -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A clash -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A clash -d "$local_ipv4" -j RETURN
iptables -t mangle -A clash -p udp -j TPROXY --on-port "$proxy_port" --tproxy-mark 1
iptables -t mangle -A PREROUTING -p udp -j clash
iptables -t nat -N CLASH_DNS
iptables -t nat -F CLASH_DNS
iptables -t nat -A CLASH_DNS -p udp -j REDIRECT --to-port 1053
iptables -t nat -I OUTPUT -p udp --dport 53 -j CLASH_DNS
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to 1053
