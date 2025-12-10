#!/bin/bash

# Ambiente de teste
#========================================================================

# - rodar o FRR simplorio para OSPF com o HOST


# Redes
#------------------------------------------------------------------------

	# Rede de contaienrs locais FRR
    docker network create \
        -d bridge \
        \
        -o "com.docker.network.bridge.name"="br-frrnet" \
        -o "com.docker.network.bridge.enable_icc"="true" \
        -o "com.docker.network.bridge.enable_ip_masquerade"="false" \
        -o "com.docker.network.driver.mtu"="1500" \
        \
        --subnet 172.28.0.0/16 --gateway 172.28.255.254 \
        --ipv6 --subnet=2001:db8:172:28::/64 --gateway=2001:db8:172:28::ffff \
        \
        frrnet;


# Varios FRR
#------------------------------------------------------------------------

    _run_frr(){
        id="$1";
        
        # numero do id com zeros a esquerda
        ID2="$id";
        [ "$id" -lt "10" ] && ID2="0$id";
        ID3="$id";
        [ "$id" -lt "100" ] && ID3="0$id";
        [ "$id" -lt "10" ] && ID3="00$id";

        # nome
        name="frr-test-$ID3";

        # - Recriar/renovar
        docker rm -f "frr-test-$ID3" 2>/dev/null;
        rm -rf   "/storage/frr-test-$ID3" 2>/dev/null;
        mkdir -p "/storage/frr-test-$ID3" 2>/dev/null;
        docker run -d \
            --restart=always \
            --name "frr-test-$ID3" -h "frr-test-$ID3.intranet.br" \
            --cpus="2.0" --memory=1g --memory-swap=1g \
            --user=root --cap-add=ALL --privileged \
            --tmpfs /run:rw,noexec,nosuid,size=1m \
            --tmpfs /tmp:rw,noexec,nosuid,size=1m \
            \
            -v /storage/frr-test-$ID3:/data \
            \
            --network frrnet \
            --ip=172.28.0.$id \
            --ip6=2001:db8:172:28::$id \
            \
            -e LOOPBACK_IPV4=10.255.255.$id \
            -e LOOPBACK_IPV6=2001:db8:10:ffff::$id \
            \
            -e SNMP_COMMUNITY=frrlab \
            -e SNMP_LOCATION=-19.99714794334259,-43.86825903886095 \
            -e SNMP_CONTACT=SMG-Patrick \
            -e SNMP_DESCRIPTION=FRR-Test-$ID3 \
            -e SNMP_PORT=48161 \
            \
            -e COUNTERS_ENABLE=yes \
            \
            -e SERVICES=mesh \
            -e FRR_TEMPLATE=router-mesh \
            -e BGP_ASN=64728 \
            \
            -e IGP_ALL_DEVS=yes \
            -e IGP_NETMODE=broadcast \
            \
            frr-server;
    };

    # Gerar containers
    for xid in $(seq 1 1 9); do
        _run_frr $xid;
    done;


exit 0;



