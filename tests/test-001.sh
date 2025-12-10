#!/bin/bash

# Ambiente de teste
#========================================================================

# - simular um ISP: FRR com RR e RS
# - varios PEs OSPFv2 e OSPFv3 ligados ao RR



# Redes
#------------------------------------------------------------------------


	# Rede de servidores no datacenter
    docker network create \
        -d bridge \
        \
        -o "com.docker.network.bridge.name"="br-datacenter" \
        -o "com.docker.network.bridge.enable_icc"="true" \
        -o "com.docker.network.bridge.enable_ip_masquerade"="false" \
        -o "com.docker.network.driver.mtu"="1500" \
        \
        --subnet 172.27.0.0/16 --gateway 172.27.255.254 \
        --ipv6 --subnet=2001:db8:172:27::/64 --gateway=2001:db8:172:27::ffff \
        \
        datacenter;


    # Configurar HOST como uplink do PE-01
    # br-datacenter

    # Criar interface vlan (tentar 3x)
    (
        # Vlan
        ip link add link br-datacenter name br-dc-vlan99 type vlan id 99;
        ip link set up dev br-dc-vlan99;
        ip -4 addr add dev br-dc-vlan99 10.75.99.1/30;
        ip -6 addr add dev br-dc-vlan99 2001:db8:10:75:99::1/126;
        # Rota para alcancar rede do laboratorio 001
        ip -4 route add 10.75.0.0/16        via 10.75.99.2            metric 1 proto static;
        ip -6 route add 2001:db8:10:75::/64 via 2001:db8:10:75:99::2  metric 1 proto static;
    ) 2>/dev/null;




# Router-Reflectors
#------------------------------------------------------------------------


# RR 01, ligado no PE01
    # - Volume
    rm -rf /storage/frr-lab-rr01;
    DATADIR=/storage/frr-lab-rr01;
    mkdir -p $DATADIR

    # - Recriar/renovar
    docker rm -f frr-lab-rr01 2>/dev/null;
    docker create \
        --restart=always \
        --name frr-lab-rr01 -h frr-lab-rr01.intranet.br \
        --cpus="2.0" --memory=2g --memory-swap=2g \
        \
        --user=root --cap-add=ALL --privileged \
        \
        --tmpfs /run:rw,noexec,nosuid,size=1m \
        --tmpfs /tmp:rw,noexec,nosuid,size=1m \
        \
        -v $DATADIR:/data \
        \
        --network datacenter \
        --ip=172.27.0.11 \
        --ip6=2001:db8:172:27::11 \
        \
        -e LOOPBACK_IPV4=10.75.255.201 \
        -e LOOPBACK_IPV6=2001:db8:10:75:255::201 \
        \
        -e SNMP_COMMUNITY=frrlab \
        -e SNMP_LOCATION=-24.00185027815257,-46.41303768445753 \
        -e SNMP_CONTACT=SMG-Patrick \
        -e SNMP_DESCRIPTION=FRR-ISP-Lab-RR-01 \
        -e SNMP_PORT=48161 \
        \
        -e FIREWALL_ENABLE=yes \
        -e FIREWALL_PERMIT_PRIVATES=yes \
        -e FIREWALL_PERMIT_NETWORKS=10.75.255.0/24,2001:db8:10:75:255::/64 \
        -e COUNTERS_ENABLE=yes \
        \
        -e SUPERGW_ENABLE=yes \
        \
        -e SERVICES=rr \
        -e FRR_TEMPLATE=router-rr-lab01 \
        -e BGP_ASN=64777 \
        \
        -e IGP_ALL_DEVS=no \
        -e IGP_NETMODE=point-to-point \
        -e VLANS="91,10.75.91.2/30,2001:db8:10:75:91::2/126" \
        \
        frr-server;

    # Iniciar RR01
    docker start frr-lab-rr01;

# RR 02
    # - Volume
    rm -rf /storage/frr-lab-rr02;
    DATADIR=/storage/frr-lab-rr02;
    mkdir -p $DATADIR

    # - Recriar/renovar
    docker rm -f frr-lab-rr02 2>/dev/null;
    docker create \
        --restart=always \
        --name frr-lab-rr02 -h frr-lab-rr02.intranet.br \
        --cpus="2.0" --memory=2g --memory-swap=2g \
        \
        --user=root --cap-add=ALL --privileged \
        \
        --tmpfs /run:rw,noexec,nosuid,size=1m \
        --tmpfs /tmp:rw,noexec,nosuid,size=1m \
        \
        -v $DATADIR:/data \
        \
        --network datacenter \
        --ip=172.27.0.12 \
        --ip6=2001:db8:172:27::12 \
        \
        -e LOOPBACK_IPV4=10.75.255.202 \
        -e LOOPBACK_IPV6=2001:db8:10:75:255::202 \
        \
        -e SNMP_COMMUNITY=frrlab \
        -e SNMP_LOCATION=-24.005849198117165,-46.404554794704495 \
        -e SNMP_CONTACT=SMG-Patrick \
        -e SNMP_DESCRIPTION=FRR-ISP-Lab-RR-02 \
        -e SNMP_PORT=48161 \
        \
        -e FIREWALL_ENABLE=yes \
        -e FIREWALL_PERMIT_PRIVATES=yes \
        -e FIREWALL_PERMIT_NETWORKS=10.75.255.0/24,2001:db8:10:75:255::/64 \
        -e COUNTERS_ENABLE=yes \
        \
        -e SUPERGW_ENABLE=yes \
        \
        -e SERVICES=rr \
        -e FRR_TEMPLATE=router-rr-lab01 \
        -e BGP_ASN=64777 \
        \
        -e IGP_ALL_DEVS=no \
        -e IGP_NETMODE=point-to-point \
        -e VLANS="95,10.75.95.2/30,2001:db8:10:75:95::2/126" \
        \
        frr-server;

    # Iniciar RR02
    docker start frr-lab-rr02;



# Routers
#------------------------------------------------------------------------



# PE 01 (liga no RR01, PE02 e PE03), uplink para HOST via vlan 99
    # - Volume
    rm -rf /storage/frr-lab-pe01;
    DATADIR=/storage/frr-lab-pe01;
    mkdir -p $DATADIR

    # - Recriar/renovar
    docker rm -f frr-lab-pe01 2>/dev/null;
    docker create \
        --restart=always \
        --name frr-lab-pe01 -h frr-lab-pe01.intranet.br \
        --cpus="2.0" --memory=2g --memory-swap=2g \
        \
        --user=root --cap-add=ALL --privileged \
        \
        --tmpfs /run:rw,noexec,nosuid,size=1m \
        --tmpfs /tmp:rw,noexec,nosuid,size=1m \
        \
        -v $DATADIR:/data \
        \
        --network datacenter \
        \
        -e LOOPBACK_IPV4=10.75.255.1 \
        -e LOOPBACK_IPV6=2001:db8:10:75:255::1 \
        \
        -e SNMP_COMMUNITY=frrlab \
        -e SNMP_LOCATION=-24.013310088422326,-46.410727102528824 \
        -e SNMP_CONTACT=SMG-Patrick \
        -e SNMP_DESCRIPTION=FRR-ISP-Lab-PE-01 \
        -e SNMP_PORT=48161 \
        \
        -e FIREWALL_ENABLE=no \
        -e COUNTERS_ENABLE=yes \
        \
        -e SERVICES=pe \
        -e FRR_TEMPLATE=router-pe-legacy \
        -e BGP_ASN=64777 \
        -e BGP_REFLECTORS=10.75.255.201,2001:db8:10:75:255::201,10.75.255.202,2001:db8:10:75:255::202 \
        \
        -e LAN_RESET=yes \
        -e GATEWAY_RESET=yes \
        -e IGP_ALL_DEVS=yes \
        -e IGP_NETMODE=point-to-point \
        -e VLANS="12,10.75.12.1/30,2001:db8:10:75:12::1/126|13,10.75.13.1/30,2001:db8:10:75:13::1/126|91,10.75.91.1/30,2001:db8:10:75:91::1/126|99,10.75.99.2/30,2001:db8:10:75:99::2/126" \
        \
        frr-server;

    # Rodar PE
    docker start frr-lab-pe01;





# PE 02 (liga no PE01 e no PE05)
    # - Volume
    rm -rf /storage/frr-lab-pe02;
    DATADIR=/storage/frr-lab-pe02;
    mkdir -p $DATADIR

    # - Recriar/renovar
    docker rm -f frr-lab-pe02 2>/dev/null;
    docker create \
        --restart=always \
        --name frr-lab-pe02 -h frr-lab-pe02.intranet.br \
        --cpus="2.0" --memory=2g --memory-swap=2g \
        \
        --user=root --cap-add=ALL --privileged \
        \
        --tmpfs /run:rw,noexec,nosuid,size=1m \
        --tmpfs /tmp:rw,noexec,nosuid,size=1m \
        \
        -v $DATADIR:/data \
        \
        --network datacenter \
        \
        -e LOOPBACK_IPV4=10.75.255.2 \
        -e LOOPBACK_IPV6=2001:db8:10:75:255::2 \
        \
        -e SNMP_COMMUNITY=frrlab \
        -e SNMP_LOCATION=-24.010453666677634,-46.42446824897751 \
        -e SNMP_CONTACT=SMG-Patrick \
        -e SNMP_DESCRIPTION=FRR-ISP-Lab-PE-02 \
        -e SNMP_PORT=48161 \
        \
        -e FIREWALL_ENABLE=no \
        -e COUNTERS_ENABLE=yes \
        \
        -e SERVICES=pe \
        -e FRR_TEMPLATE=router-pe-legacy \
        -e BGP_ASN=64777 \
        -e BGP_REFLECTORS=10.75.255.201,2001:db8:10:75:255::201,10.75.255.202,2001:db8:10:75:255::202 \
        \
        -e LAN_RESET=yes \
        -e GATEWAY_RESET=yes \
        -e IGP_ALL_DEVS=no \
        -e IGP_NETMODE=point-to-point \
        -e VLANS="12,10.75.12.2/30,2001:db8:10:75:12::2/126|25,10.75.25.1/30,2001:db8:10:75:25::1/126" \
        \
        frr-server;

    # Rodar PE
    docker start frr-lab-pe02;




# PE 03 (liga no PE01 e no PE04)
    # - Volume
    rm -rf /storage/frr-lab-pe03;
    DATADIR=/storage/frr-lab-pe03;
    mkdir -p $DATADIR

    # - Recriar/renovar
    docker rm -f frr-lab-pe03 2>/dev/null;
    docker create \
        --restart=always \
        --name frr-lab-pe03 -h frr-lab-pe03.intranet.br \
        --cpus="2.0" --memory=2g --memory-swap=2g \
        \
        --user=root --cap-add=ALL --privileged \
        \
        --tmpfs /run:rw,noexec,nosuid,size=1m \
        --tmpfs /tmp:rw,noexec,nosuid,size=1m \
        \
        -v $DATADIR:/data \
        \
        --network datacenter \
        \
        -e LOOPBACK_IPV4=10.75.255.3 \
        -e LOOPBACK_IPV6=2001:db8:10:75:255::3 \
        \
        -e SNMP_COMMUNITY=frrlab \
        -e SNMP_LOCATION=-24.002427726273666,-46.42467643553602 \
        -e SNMP_CONTACT=SMG-Patrick \
        -e SNMP_DESCRIPTION=FRR-ISP-Lab-PE-03 \
        -e SNMP_PORT=48161 \
        \
        -e FIREWALL_ENABLE=no \
        -e COUNTERS_ENABLE=yes \
        \
        -e SERVICES=pe \
        -e FRR_TEMPLATE=router-pe-legacy \
        -e BGP_ASN=64777 \
        -e BGP_REFLECTORS=10.75.255.201,2001:db8:10:75:255::201,10.75.255.202,2001:db8:10:75:255::202 \
        \
        -e LAN_RESET=yes \
        -e GATEWAY_RESET=yes \
        -e IGP_ALL_DEVS=no \
        -e IGP_NETMODE=point-to-point \
        -e VLANS="13,10.75.13.2/30,2001:db8:10:75:13::2/126|34,10.75.34.1/30,2001:db8:10:75:34::1/126" \
        \
        frr-server;

    # Rodar PE
    docker start frr-lab-pe03;




# PE 04 (liga no PE03 e no PE05)
    # - Volume
    rm -rf /storage/frr-lab-pe04;
    DATADIR=/storage/frr-lab-pe04;
    mkdir -p $DATADIR

    # - Recriar/renovar
    docker rm -f frr-lab-pe04 2>/dev/null;
    docker create \
        --restart=always \
        --name frr-lab-pe04 -h frr-lab-pe04.intranet.br \
        --cpus="2.0" --memory=2g --memory-swap=2g \
        \
        --user=root --cap-add=ALL --privileged \
        \
        --tmpfs /run:rw,noexec,nosuid,size=1m \
        --tmpfs /tmp:rw,noexec,nosuid,size=1m \
        \
        -v $DATADIR:/data \
        \
        --network datacenter \
        \
        -e LOOPBACK_IPV4=10.75.255.4 \
        -e LOOPBACK_IPV6=2001:db8:10:75:255::4 \
        \
        -e SNMP_COMMUNITY=frrlab \
        -e SNMP_LOCATION=-24.00409846478712,-46.4308496608323 \
        -e SNMP_CONTACT=SMG-Patrick \
        -e SNMP_DESCRIPTION=FRR-ISP-Lab-PE-04 \
        -e SNMP_PORT=48161 \
        \
        -e FIREWALL_ENABLE=no \
        -e COUNTERS_ENABLE=yes \
        \
        -e SERVICES=pe \
        -e FRR_TEMPLATE=router-pe-legacy \
        -e BGP_ASN=64777 \
        -e BGP_REFLECTORS=10.75.255.201,2001:db8:10:75:255::201,10.75.255.202,2001:db8:10:75:255::202 \
        \
        -e LAN_RESET=yes \
        -e GATEWAY_RESET=yes \
        -e IGP_ALL_DEVS=no \
        -e IGP_NETMODE=point-to-point \
        -e VLANS="34,10.75.34.2/30,2001:db8:10:75:34::2/126|45,10.75.45.1/30,2001:db8:10:75:45::1/126" \
        \
        frr-server;

    # Rodar PE
    docker start frr-lab-pe04;




# PE 05 (liga no PE02 e no PE04)
    # - Volume
    rm -rf /storage/frr-lab-pe05;
    DATADIR=/storage/frr-lab-pe05;
    mkdir -p $DATADIR

    # - Recriar/renovar
    docker rm -f frr-lab-pe05 2>/dev/null;
    docker create \
        --restart=always \
        --name frr-lab-pe05 -h frr-lab-pe05.intranet.br \
        --cpus="2.0" --memory=2g --memory-swap=2g \
        \
        --user=root --cap-add=ALL --privileged \
        \
        --tmpfs /run:rw,noexec,nosuid,size=1m \
        --tmpfs /tmp:rw,noexec,nosuid,size=1m \
        \
        -v $DATADIR:/data \
        \
        --network datacenter \
        \
        -e LOOPBACK_IPV4=10.75.255.5 \
        -e LOOPBACK_IPV6=2001:db8:10:75:255::5 \
        \
        -e SNMP_COMMUNITY=frrlab \
        -e SNMP_LOCATION=-24.016869424861017,-46.43695052152716 \
        -e SNMP_CONTACT=SMG-Patrick \
        -e SNMP_DESCRIPTION=FRR-ISP-Lab-PE-05 \
        -e SNMP_PORT=48161 \
        \
        -e FIREWALL_ENABLE=no \
        -e COUNTERS_ENABLE=yes \
        \
        -e SERVICES=pe \
        -e FRR_TEMPLATE=router-pe-legacy \
        -e BGP_ASN=64777 \
        -e BGP_REFLECTORS=10.75.255.201,2001:db8:10:75:255::201,10.75.255.202,2001:db8:10:75:255::202 \
        \
        -e LAN_RESET=yes \
        -e GATEWAY_RESET=yes \
        -e IGP_ALL_DEVS=no \
        -e IGP_NETMODE=point-to-point \
        -e VLANS="25,10.75.25.2/30,2001:db8:10:75:25::2/126|45,10.75.45.2/30,2001:db8:10:75:45::2/126|95,10.75.95.1/30,2001:db8:10:75:95::1/126" \
        \
        frr-server;

    # Rodar PE
    docker start frr-lab-pe05;






