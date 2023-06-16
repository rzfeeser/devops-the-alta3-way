#!/bin/bash

grn="\033[32m"
wht="\033[0m"

printf "${grn}Hello World${wht}\n"

set -eou pipefail

# namespace
echo "Setting up the network namespaces"
sudo ip netns add ohost
sudo ip netns add phost    
sudo ip netns add whost
sudo ip netns add yhost
sudo ip netns add prouter
sudo ip netns add yrouter
sudo ip netns add wrouter
sudo ip netns add orouter
sudo ip netns add crouter

# ethernet bridges
echo "Setting Ethernet Bridges"
sudo ip link add name pbridge type bridge
sudo ip link add name obridge type bridge
sudo ip link add name ybridge type bridge
sudo ip link add name wbridge type bridge
sudo ip link set dev pbridge up
sudo ip link set dev obridge up
sudo ip link set dev ybridge up
sudo ip link set dev wbridge up
brctl show
ip l -c

# Veths
echo "Setting Veths"
sudo ip netns exec phost ip link | grep -A 2 phost
sudo ip netns exec yhost ip link | grep -A 2 yhost
sudo ip netns exec whost ip link | grep -A 2 whost
sudo ip netns exec ohost ip link | grep -A 2 ohost
sudo ip netns exec crouter ip link | grep -A 5 router
sudo ip netns exec prouter ip link | grep -A 2 prouter
sudo ip netns exec yrouter ip link | grep -A 2 yrouter
sudo ip netns exec wrouter ip link | grep -A 2 wrouter
sudo ip netns exec orouter ip link | grep -A 2 orouter
ip l -c


# IP Forwarding
echo "Setting IP Forwarding"
echo 'net.ipv4.ip_forward = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.all.forwarding = 1' | sudo tee /etc/sysctl.d/10-ip-forwarding.conf

sudo ip netns exec prouter sysctl -p /etc/sysctl.d/10-ip-forwarding.conf
sudo ip netns exec yrouter sysctl -p /etc/sysctl.d/10-ip-forwarding.conf
sudo ip netns exec wrouter sysctl -p /etc/sysctl.d/10-ip-forwarding.conf
sudo ip netns exec orouter sysctl -p /etc/sysctl.d/10-ip-forwarding.conf
sudo ip netns exec crouter sysctl -p /etc/sysctl.d/10-ip-forwarding.conf

# Assign IP Addresses
echo "Assigning IP addresses"
# phost LAN link
sudo ip netns exec phost ip addr add 10.1.1.21/24 dev phost2pbrg
sudo ip netns exec phost ip link set dev phost2pbrg up
sudo ip netns exec phost ip link set dev lo up

# prouter LAN link
sudo ip netns exec prouter ip addr add 10.1.1.1/24 dev prout2pbrg
sudo ip netns exec prouter ip link set dev prout2pbrg up
sudo ip netns exec prouter ip link set dev lo up

# ohost LAN link
sudo ip netns exec ohost ip addr add 10.1.4.21/24 dev ohost2obrg
sudo ip netns exec ohost ip link set dev ohost2obrg up
sudo ip netns exec ohost ip link set dev lo up

# orouter LAN link
sudo ip netns exec orouter ip addr add 10.1.4.1/24 dev orout2obrg
sudo ip netns exec orouter ip link set dev orout2obrg up
sudo ip netns exec orouter ip link set dev lo up

# yhostA LAN link
sudo ip netns exec yhost ip addr add 10.1.2.21/24 dev yhost2ybrg
sudo ip netns exec yhost ip link set dev yhost2ybrg up
sudo ip netns exec yhost ip link set dev lo up

# yrouter LAN link
sudo ip netns exec yrouter ip addr add 10.1.2.1/24 dev yrout2ybrg
sudo ip netns exec yrouter ip link set dev yrout2ybrg up
sudo ip netns exec yrouter ip link set dev lo up

# whost LAN link
sudo ip netns exec whost ip addr add 10.1.3.21/24 dev whost2wbrg
sudo ip netns exec whost ip link set dev whost2wbrg up
sudo ip netns exec whost ip link set dev lo up

# wrouterA LAN link
sudo ip netns exec wrouter ip addr add 10.1.3.1/24 dev wrout2wbrg
sudo ip netns exec wrouter ip link set dev wrout2wbrg up
sudo ip netns exec wrouter ip link set dev lo up

# PURPLE WAN LINK (number 1)
   # PROUTER -> CROUTER
sudo ip netns exec prouter ip addr add 10.1.5.2/30 dev prout2crout
sudo ip netns exec prouter ip link set dev prout2crout up
sudo ip netns exec prouter ip link set dev lo up
   # CROUTER -> PROUTER WAN link
sudo ip netns exec crouter ip addr add 10.1.5.1/30 dev crout2prout
sudo ip netns exec crouter ip link set dev crout2prout up
sudo ip netns exec crouter ip link set dev lo up

# YELLOW WAN LINK (number 2)
  # YROUTER -> CROUTER WAN LINK
sudo ip netns exec yrouter ip addr add 10.1.5.6/30 dev yrout2crout
sudo ip netns exec yrouter ip link set dev yrout2crout up
sudo ip netns exec yrouter ip link set dev lo up
  # CROUTER -> YROUTER WAN LINK
sudo ip netns exec crouter ip addr add 10.1.5.5/30 dev crout2yrout
sudo ip netns exec crouter ip link set dev crout2yrout up
sudo ip netns exec crouter ip link set dev lo up

# WHITE WAN LINK (number 3)
  # WROUTER -> CROUTER 
sudo ip netns exec wrouter ip addr add 10.1.5.10/30 dev wrout2crout
sudo ip netns exec wrouter ip link set dev wrout2crout up
sudo ip netns exec wrouter ip link set dev lo up
  # CROUTER -> WROUTER
sudo ip netns exec crouter ip addr add 10.1.5.9/30 dev crout2wrout
sudo ip netns exec crouter ip link set dev crout2wrout up
sudo ip netns exec crouter ip link set dev lo up

# ORANGE WAN LINK (number 4)
  # OROUTER -> CROUTER
sudo ip netns exec orouter ip addr add 10.1.5.14/30 dev orout2crout
sudo ip netns exec orouter ip link set dev orout2crout up
sudo ip netns exec orouter ip link set dev lo up
  # CROUTER -> OROUTER
sudo ip netns exec crouter ip addr add 10.1.5.13/30 dev crout2orout
sudo ip netns exec crouter ip link set dev crout2orout up
sudo ip netns exec crouter ip link set dev lo up

#Static Routes
echo "Setting static routes"
# Configure routes on the core router
sudo ip netns exec crouter ip route add 10.1.1.0/24 via 10.1.5.2
sudo ip netns exec crouter ip route add 10.1.2.0/24 via 10.1.5.6
sudo ip netns exec crouter ip route add 10.1.3.0/24 via 10.1.5.10
sudo ip netns exec crouter ip route add 10.1.4.0/24 via 10.1.5.14
sudo ip netns exec crouter ip route add default via 10.1.5.18

#Configure default routes on the hosts
sudo ip netns exec phost ip route add default via 10.1.1.1
sudo ip netns exec yhost ip route add default via 10.1.2.1
sudo ip netns exec whost ip route add default via 10.1.3.1
sudo ip netns exec ohost ip route add default via 10.1.4.1

#Configure the default routes on the edge routers
sudo ip netns exec prouter ip route add default via 10.1.5.1
sudo ip netns exec yrouter ip route add default via 10.1.5.5
sudo ip netns exec wrouter ip route add default via 10.1.5.9
sudo ip netns exec orouter ip route add default via 10.1.5.13

#DHCP
echo "setting dhcp"
sudo ip netns add phost2-ns  
sudo ip link add phost2A type veth peer name phost2Z  
sudo ip link set phost2A netns phost2-ns  
sudo ip link set dev phost2Z master pbridge  
sudo ip netns exec phost2-ns dhclient phost2A  
sudo ip netns exec phost2-ns ip -c addr
