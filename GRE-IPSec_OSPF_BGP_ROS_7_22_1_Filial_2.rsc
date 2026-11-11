# RouterOS 7.22.1

/interface bridge
add name=lo-bgp

/interface gre
add allow-fast-path=no keepalive=30s local-address=192.0.2.1 mtu=1398 name=to_CU \
    remote-address=203.0.113.1
add allow-fast-path=no keepalive=30s local-address=192.0.2.1 mtu=1398 name=to_Filial_1 \
    remote-address=198.51.100.1

/interface list
add name=GRE
add name=WAN

/interface list member
add interface=to_CU list=GRE
add interface=to_Filial_1 list=GRE
add interface=ether1 list=WAN

/ip address
add address=192.0.2.1/24 interface=ether1 network=192.0.2.0
add address=10.30.0.1/24 interface=ether2 network=10.30.0.0
add address=10.254.0.3 interface=lo-bgp network=10.254.0.3
add address=172.16.2.2/30 interface=to_CU network=172.16.2.0
add address=172.16.3.2/30 interface=to_Filial_1 network=172.16.3.0

/ip route
add dst-address=0.0.0.0/0 gateway=192.0.2.254 routing-table=main

/ip firewall filter
add action=accept chain=input src-address-list=filials
add action=accept chain=input in-interface-list=GRE

add action=accept chain=forward in-interface-list=GRE
add action=accept chain=forward out-interface-list=GRE
add action=accept chain=forward dst-address=10.30.0.0/24 src-address-list=vpn_ext
add action=accept chain=forward dst-address-list=vpn_ext src-address=10.30.0.0/24
add action=accept chain=forward protocol=icmp

add action=accept chain=output dst-address-list=filials
add action=accept chain=output out-interface-list=GRE

/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=WAN

/routing bgp instance
add as=65530 disabled=no name=default router-id=10.254.0.3

/routing bgp connection
add as=65530 disabled=no instance=default local.address=10.254.0.3 local.role=ibgp multihop=yes\
    name=to_CU output.network=bgp_networks remote.address=10.254.0.1/32 remote.as=65530 \
    routing-table=main
add as=65530 disabled=no instance=default local.address=10.254.0.3 local.role=ibgp multihop=yes \
    name=to_Filial_1 output.network=bgp_networks remote.address=10.254.0.2/32 remote.as=65530 \
    routing-table=main

/routing ospf instance
add disabled=no name=default router-id=10.254.0.3

/routing ospf area
add disabled=no instance=default name=backbone

/routing ospf interface-template
add area=backbone cost=10 disabled=no interfaces=to_CU type=ptp
add area=backbone cost=100 disabled=no interfaces=to_Filial_1 type=ptp
add area=backbone disabled=no interfaces=lo-bgp networks=10.254.0.3/32 \
    passive
