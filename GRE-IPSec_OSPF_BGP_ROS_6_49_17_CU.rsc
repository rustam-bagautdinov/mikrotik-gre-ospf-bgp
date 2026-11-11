# RouterOS 6.49.17

/interface bridge
add name=lo-bgp protocol-mode=none

/interface gre
add allow-fast-path=no ipsec-secret=**** local-address=203.0.113.1 \
    mtu=1398 name=to_Filial_1 remote-address=198.51.100.1
add allow-fast-path=no ipsec-secret=**** local-address=203.0.113.1 \
    mtu=1398 name=to_Filial_2 remote-address=192.0.2.1

/interface list
add name=GRE
add name=WAN

/interface list member
add interface=to_Filial_1 list=GRE
add interface=to_Filial_2 list=GRE
add interface=ether1 list=WAN

/ip address
add address=203.0.113.1/24 interface=ether1 network=203.0.113.0
add address=10.254.0.1 interface=lo-bgp network=10.254.0.1
add address=172.16.1.1/30 interface=to_Filial_1 network=172.16.1.0
add address=172.16.2.1/30 interface=to_Filial_2 network=172.16.2.0

/ip route
add distance=1 gateway=203.0.113.254

/ip firewall address-list
add address=192.168.100.0/24 list=vpn_ext
add address=198.51.100.1 list=filials
add address=192.0.2.1 list=filials

/ip firewall filter
add action=accept chain=input src-address-list=filials
add action=accept chain=input in-interface-list=GRE

add action=accept chain=forward in-interface-list=GRE
add action=accept chain=forward out-interface-list=GRE
add action=accept chain=forward dst-address=10.10.0.0/24 src-address-list=vpn_ext
add action=accept chain=forward dst-address-list=vpn_ext src-address=10.10.0.0/24
add action=accept chain=forward protocol=icmp

add action=accept chain=output dst-address-list=filials
add action=accept chain=output out-interface-list=GRE

/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=WAN

/routing bgp instance
set default as=65530 router-id=10.254.0.1

/routing bgp network
add network=10.10.0.0/24 synchronize=no

/routing bgp peer
add multihop=yes name=to_Filial_1 nexthop-choice=force-self remote-address=10.254.0.2 \
    remote-as=65530 route-reflect=yes update-source=lo-bgp
add multihop=yes name=to_Filial_2 nexthop-choice=force-self remote-address=10.254.0.3 \
    remote-as=65530 route-reflect=yes update-source=lo-bgp

/routing ospf instance
set [ find default=yes ] router-id=10.254.0.1

/routing ospf interface
add cost=10 interface=to_Filial_1 network-type=point-to-point
add cost=10 interface=to_Filial_2 network-type=point-to-point

/routing ospf network
add area=backbone network=10.254.0.1/32
add area=backbone network=172.16.1.0/30
add area=backbone network=172.16.2.0/30
