#!/bin/bash

# Gerar configuracao do equipamento - modo PE padrao (IPv4 e IPv6)
#========================================================================

    initlogfile="/data/logs/init.log";
    _logit(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|router-pe: $@" >> $initlogfile; };

    _logit "Iniciando gerador de template";

    # Incluir config das variaveis de ambiente
    SYS_ENV="/opt/env.sh";
    [ -s "$SYS_ENV" ] && . $SYS_ENV;

    # Cabecalhos basicos
    cat /opt/shared/frr-header.conf;
    cat /opt/shared/frr-hostname.conf;
    cat /opt/shared/frr-logging.conf;
    [ "$SNMP_ENABLE" = "yes" ] && cat /opt/shared/frr-snmp-agentx.conf;
    cat /opt/shared/frr-forwarding.conf;
    cat /opt/shared/frr-basic-rp.conf;
    cat /opt/shared/frr-debugs.conf;
    cat /opt/shared/frr-std-rid.conf;

    # Interfaces na rede ospf/igp
    VCOUNT=0;
    VDEVS="";
    _logit "Analisando IGP_ALL_DEVS=$IGP_ALL_DEVS";
    if [ "$IGP_ALL_DEVS" = "no" ]; then
        # - somente vlans
        # - somente VIDs menores que 1000
        cd /sys/class/net/;
        for dev in eth*; do
            [ -d "$dev" ] || continue;
            vid=$(echo $dev | cut -f2 -d'.' -s);
            # nao e' vlan
            [ "x$vid" = "x" ] && continue;

            # nao e' vlan abaixo de 1000 (2-999)
            [ "$vid" -lt "1000" ] || continue;

            # Achou
            VCOUNT=$(($VCOUNT+1));
            VDEVS="$VDEVS $dev";
        done;
    fi;
    _logit "VDEVS IGP: $VDEVS";

    # Se nao houver VIDs, usar eths
    cd /sys/class/net/;
    if [ "$VCOUNT" = "0" ]; then
        for dev in eth*; do
            [ -d "$dev" ] || continue;
            VCOUNT=$(($VCOUNT+1));
            VDEVS="$VDEVS $dev";
        done;
    fi;
    _logit "VDEVS ETHs: $VDEVS";

    # Sem interfaces ainda... declarar eth0
    # como padrao
    [ "$VCOUNT" = "0" ] && {
        VDEVS="eth0";
    };

    # Retirar repeticao
    tmplist=$(for x in $VDEVS; do echo $x; done | sort -u);
    VDEVS=$(echo $tmplist);
    _logit "VDEVS FINAL: $VDEVS";


    # Declarar interfaces no backbone
    for dev in $VDEVS; do
        echo "interface $dev";
        echo " ip ospf area 0.0.0.0";
        echo " ip ospf bfd";
        echo " ip ospf bfd profile PEPEERS";
        echo " ip ospf cost 1";
        echo " ip ospf network $IGP_NETMODE";
        echo " ipv6 ospf6 area 0.0.0.0";
        echo " ipv6 ospf6 bfd";
        echo " ipv6 ospf6 bfd profile PEPEERS";
        echo " ipv6 ospf6 cost 1";
        echo " ipv6 ospf6 network $IGP_NETMODE";
        echo "exit";
        echo "!";
    done;

    # Declarar loopback
    cat /opt/shared/frr-ospf-lo.conf;


    # Analise de peerings
    BGP_PEERS=$(echo $BGP_REFLECTORS | sed 's#,# #g');
    IBGP_V4_PEERS="";
    IBGP_V6_PEERS="";
    for addr in $BGP_PEERS; do
        tst=$(echo $addr | egrep -q ':'); sn="$?";
        [ "$sn" = "0" ] || IBGP_V4_PEERS="$IBGP_V4_PEERS $addr";
        [ "$sn" = "0" ] && IBGP_V6_PEERS="$IBGP_V6_PEERS $addr";
    done;

    _logit "Peers iBGP IPv4: $IBGP_V4_PEERS";
    _logit "Peers iBGP IPv6: $IBGP_V6_PEERS";

    # Declarar UP para RRs
    (
        echo "router bgp %BGP_ASN%";
        echo " bgp suppress-fib-pending";
        echo " bgp log-neighbor-changes";
        echo " bgp always-compare-med";
        echo " no bgp ebgp-requires-policy";
        echo " no bgp default ipv4-unicast";
        echo " bgp deterministic-med";
        echo " bgp bestpath as-path multipath-relax";
        echo " bgp route-reflector allow-outbound-policy";
        echo " bgp bestpath med confed missing-as-worst";
        echo " no bgp network import-check";

        echo " neighbor REFLECTORSV4 peer-group";
        echo " neighbor REFLECTORSV4 remote-as internal";
        echo " neighbor REFLECTORSV4 description Router-Reflectors-IPv4";
        echo " neighbor REFLECTORSV4 update-source %SOURCE_IPV4%";
        echo " neighbor REFLECTORSV4 timers 3 12";

        echo " neighbor REFLECTORSV6 peer-group";
        echo " neighbor REFLECTORSV6 remote-as internal";
        echo " neighbor REFLECTORSV6 description Router-Reflectors-IPv6";
        echo " neighbor REFLECTORSV6 update-source %SOURCE_IPV6%";
        echo " neighbor REFLECTORSV6 timers 3 12";

        # Peerings IPv4
        for addr in $IBGP_V4_PEERS; do
            echo " neighbor $addr peer-group REFLECTORSV4";
            echo " neighbor $addr bfd profile RRPEERS";
        done;
        # Peerings IPv6
        for addr in $IBGP_V6_PEERS; do
            echo " neighbor $addr peer-group REFLECTORSV6";
            echo " neighbor $addr bfd profile RRPEERS";
        done;

        echo " bgp allow-martian-nexthop";
        echo " !";

        echo " address-family ipv4 unicast";
        echo "  neighbor REFLECTORSV4 activate";
        echo "  neighbor REFLECTORSV4 soft-reconfiguration inbound";
        echo "  neighbor REFLECTORSV4 route-map RR-IMPORT-IPV4 in";
        echo "  neighbor REFLECTORSV4 route-map RR-EXPORT-IPV4 out";
        echo "  maximum-paths 64";
        echo "  maximum-paths ibgp 64";
        echo " exit-address-family";
        echo " !";

        echo " address-family ipv4 vpn";
        echo "  neighbor REFLECTORSV4 activate";
        echo "  neighbor REFLECTORSV4 soft-reconfiguration inbound";
        echo "  neighbor REFLECTORSV4 route-map VPN-IMPORT-IPV4 in";
        echo "  neighbor REFLECTORSV4 route-map VPN-EXPORT-IPV4 out";
        echo " exit-address-family";
        echo " !";

        echo " address-family ipv6 unicast";
        echo "  neighbor REFLECTORSV6 activate";
        echo "  neighbor REFLECTORSV6 soft-reconfiguration inbound";
        echo "  neighbor REFLECTORSV6 route-map RR-IMPORT-IPV6 in";
        echo "  neighbor REFLECTORSV6 route-map RR-EXPORT-IPV6 out";
        echo "  maximum-paths 64";
        echo "  maximum-paths ibgp 64";
        echo " exit-address-family";
        echo " !";

        echo " address-family ipv6 vpn";
        echo "  neighbor REFLECTORSV6 activate";
        echo "  neighbor REFLECTORSV6 soft-reconfiguration inbound";
        echo "  neighbor REFLECTORSV6 route-map VPN-IMPORT-IPV6 in";
        echo "  neighbor REFLECTORSV6 route-map VPN-EXPORT-IPV6 out";
        echo " exit-address-family";
        echo "exit";

        echo "!";
    );

    # Instancia ospf basica
    cat /opt/shared/frr-ospfv2-basic.conf;
    cat /opt/shared/frr-ospfv3-basic.conf;

    # Declarar BFD basico
    cat /opt/shared/frr-bfd-rr-pe.conf;



exit 0;

