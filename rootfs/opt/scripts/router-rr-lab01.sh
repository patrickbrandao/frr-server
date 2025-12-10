#!/bin/bash

# Gerar configuracao do equipamento - modo PE legacy (paradigma IP)
#========================================================================

    initlogfile="/data/logs/init.log";
    _logit(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|router-rr-lab01: $@" >> $initlogfile; };

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

    # BGP RR Aberto
    cat /opt/shared/frr-rr-legacy-open.conf;


    # Instancia ospf basica
    cat /opt/shared/frr-ospfv2-basic.conf;
    cat /opt/shared/frr-ospfv3-basic.conf;


    # Declarar BFD basico
    cat /opt/shared/frr-bfd-rr-pe.conf;



exit 0;



