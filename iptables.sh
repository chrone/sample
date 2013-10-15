#!/bin/bash
WAN_DEVICE=eth0

# stop iptables
sysctl -w net.ipv4.ip_forward=0 > /dev/null
service iptables stop

# PMTU
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Default Rule
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# fragment packets
iptables -N fragment
iptables -A fragment -j DROP
iptables -A INPUT -f -j fragment
iptables -A FORWARD -f -j fragment

# IP Spoofing
iptables -N spoofing
iptables -A spoofing -j DROP
iptables -A INPUT -i ${WAN_DEVICE} -s 127.0.0.0/8    -j spoofing
iptables -A INPUT -i ${WAN_DEVICE} -s 10.0.0.0/8     -j spoofing
iptables -A INPUT -i ${WAN_DEVICE} -s 172.16.0.0/12  -j spoofing
iptables -A INPUT -i ${WAN_DEVICE} -s 192.168.0.0/16 -j spoofing
iptables -A FORWARD -i ${WAN_DEVICE} -s 127.0.0.0/8    -j spoofing
iptables -A FORWARD -i ${WAN_DEVICE} -s 10.0.0.0/8     -j spoofing
iptables -A FORWARD -i ${WAN_DEVICE} -s 172.16.0.0/12  -j spoofing
iptables -A FORWARD -i ${WAN_DEVICE} -s 192.168.0.0/16 -j spoofing

# NetBIOS in WAN
iptables -A INPUT -i ${WAN_DEVICE} -p tcp -m multiport --dports 135,137,138,139,445 -j DROP
iptables -A INPUT -i ${WAN_DEVICE} -p udp -m multiport --dports 135,137,138,139,445 -j DROP
iptables -A OUTPUT -o ${WAN_DEVICE} -p tcp -m multiport --sports 135,137,138,139,445 -j DROP
iptables -A OUTPUT -o ${WAN_DEVICE} -p udp -m multiport --sports 135,137,138,139,445 -j DROP
iptables -A FORWARD -i ${WAN_DEVICE} -p tcp -m multiport --dports 135,137,138,139,445 -j DROP
iptables -A FORWARD -i ${WAN_DEVICE} -p udp -m multiport --dports 135,137,138,139,445 -j DROP
iptables -A FORWARD -o ${WAN_DEVICE} -p tcp -m multiport --sports 135,137,138,139,445 -j DROP
iptables -A FORWARD -o ${WAN_DEVICE} -p udp -m multiport --sports 135,137,138,139,445 -j DROP

# Ping of Death
iptables -N pingdeath
iptables -A pingdeath -m limit --limit 1/s --limit-burst 4 -j ACCEPT
iptables -A pingdeath -j DROP
iptables -A INPUT -p icmp --icmp-type echo-request -j pingdeath
iptables -A FORWARD ! -o ${WAN_DEVICE} -p icmp --icmp-type echo-request -j pingdeath

# lo ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# Response packets
iptables -A INPUT -i ${WAN_DEVICE} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i ${WAN_DEVICE} -m state --state ESTABLISHED,RELATED -j ACCEPT

# ICMP packets in WAN
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type source-quench -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A INPUT -p icmp --icmp-type parameter-problem -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type source-quench -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type parameter-problem -j ACCEPT

# IDENT
iptables -A INPUT -p tcp --dport 113 -j REJECT --reject-with tcp-reset
iptables -A FORWARD -p tcp --dport 113 -j REJECT --reject-with tcp-reset

## WAN Services
# SSH
iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 22 -j ACCEPT

# Telnet
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 23 -j ACCEPT

# DNS
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 53 -j ACCEPT
#iptables -A INPUT -i ${WAN_DEVICE} -p udp --dport 53 -j ACCEPT

# HTTP
iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 80 -j ACCEPT

# HTTPS
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 443 -j ACCEPT

# FTP
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 21 -j ACCEPT

# FTP PASV
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 64001:64005 -j ACCEPT

# SMTP
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 25 -j ACCEPT

# SMTPS
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 465 -j ACCEPT

# POP3
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 110 -j ACCEPT

# POP3S
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 995 -j ACCEPT

# IMAP
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 143 -j ACCEPT

# IMAPS
#iptables -A INPUT -i ${WAN_DEVICE} -p tcp --dport 993 -j ACCEPT

# NAT example
#iptables -A FORWARD -i ${WAN_DEVICE} -p tcp -d 192.168.100.101 --dport 80 -j ACCEPT
#iptables -t nat -A PREROUTING -i ${WAN_DEVICE} -p tcp --dport 1080 -j DNAT --to-destination 192.168.100.101:80
# NAT example (range)
#iptables -A FORWARD -i ${WAN_DEVICE} -p tcp -d 192.168.100.101 --dport 5900:5901 -j ACCEPT
#iptables -t nat -A PREROUTING -i ${WAN_DEVICE} -p tcp --dport 15900:15901 -j DNAT --to-destination 192.168.100.101:5900-5901

iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

# start iptables
service iptables save
service iptables start
sysctl -w net.ipv4.ip_forward=1 > /dev/null
