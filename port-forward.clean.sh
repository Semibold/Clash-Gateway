#!/bin/bash

set -e

ip rule del fwmark 1 table 100
ip route del local default dev lo table 100

iptables -t mangle -D PREROUTING -j clash
iptables -t mangle -F clash
iptables -t mangle -X clash

iptables -t nat -D PREROUTING -p udp --dport 53 -j CLASH_DNS
iptables -t nat -F CLASH_DNS
iptables -t nat -X CLASH_DNS
