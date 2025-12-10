#!/bin/bash


# Carregar variaveis, se presentes
    # Se o arquivo em /run existir e' porque
    # o entrypoint ja foi executado e estamos
    # dentro de um script do container
    SYS_ENV="/run/env.sh";
    if [ -f "$SYS_ENV" ]; then
        # Carregar variaveis exportadas pelo entrypoint
        . $SYS_ENV;
    fi;

# Critica - Normalizar valores e definir padroes
    # - firewall de protecao do container
    [ "x$FIREWALL_ENABLE"           = "x" ] && FIREWALL_ENABLE="no";
    [ "$FIREWALL_ENABLE"          = "yes" ] || FIREWALL_ENABLE="no";
    [ "x$FIREWALL_PERMIT_PRIVATES"  = "x" ] && FIREWALL_PERMIT_PRIVATES="yes";
    [ "$FIREWALL_PERMIT_PRIVATES"  = "no" ] || FIREWALL_PERMIT_PRIVATES="yes";
    [ "x$FIREWALL_PERMIT_NETWORKS"  = "x" ] && FIREWALL_PERMIT_NETWORKS="198.18.0.0/15";

    # - contador de pacotes
    [ "x$COUNTERS_ENABLE"           = "x" ] && COUNTERS_ENABLE="yes";
    [ "$COUNTERS_ENABLE"           = "no" ] || COUNTERS_ENABLE="yes";
    

    # - controle de log em arquivo
    [ "x$LOGSERVER_ENABLE" = "x"  ] && LOGSERVER_ENABLE="no";
    [ "$LOGSERVER_ENABLE" = "yes" ] || LOGSERVER_ENABLE="no";
    [ "x$LOGSERVER_HOST" = "x"   ] && {
        LOGSERVER_HOST="127.0.0.1";
        LOGSERVER_ENABLE="no";
    }
    [ "x$LOGSERVER_PORT" = "x"   ] && LOGSERVER_PORT="514";


    # - subir IGP em todas as interfaces?
    [ "x$IGP_NETMODE" = "x"  ] && IGP_NETMODE="broadcast";
    [ "x$IGP_ALL_DEVS" = "x"  ] && IGP_ALL_DEVS="yes";
    [ "$IGP_ALL_DEVS"  = "no" ] || IGP_ALL_DEVS="yes";

    # - vlans do container
    [ "x$INTERFACE" = "x"   ] && INTERFACE="eth0";
    [ "x$VLANS" = "x"   ] && VLANS="";

    # - apagar rede docker?
    [ "x$LAN_RESET" = "x"  ] && LAN_RESET="no";
    [ "$LAN_RESET" = "yes" ] || LAN_RESET="no";

    # - apagar gateway docker?
    [ "x$GATEWAY_RESET" = "x"  ] && GATEWAY_RESET="no";
    [ "$GATEWAY_RESET" = "yes" ] || GATEWAY_RESET="no";

    # - config de roteamento
    [ "x$SUPERGW_ENABLE" = "x"  ] && SUPERGW_ENABLE="no";
    [ "$SUPERGW_ENABLE" = "yes" ] || SUPERGW_ENABLE="no";

    # - instalar rotas na fib?
    [ "x$FIB_ENABLE" = "x" ] && FIB_ENABLE="yes";
    [ "$FIB_ENABLE" = "no" ] || FIB_ENABLE="yes";

    # - servicos a rodar
    [ "x$SERVICES" = "x"   ] && SERVICES="all";



# Critica - Variaveis usadas em templates prontos
    # Variaveis fixas
    FRR_STATE_DIR="/run/frr";
    FRR_RUN_DIR="/run/frr";

    # - Template de configuracao inicial
    #   Requer arquivo .conf em /opt/shared/FRR_TEMPLATE.conf
    [ "x$FRR_TEMPLATE" = "x"  ] && FRR_TEMPLATE="router-pe";

    # - Arquivo de log do frr
    [ "x$FRR_LOGFILE" = "x"  ] && FRR_LOGFILE="/data/logs/frr.log";

    # - ASN padrao dos templates BGP
    [ "x$BGP_ASN" = "x" ] && BGP_ASN="64900";

    # - RouterID padrao
    [ "x$ROUTER_ID" = "x" ] && ROUTER_ID=$(head -1 /run/router-id-default 2>/dev/null);
    [ "x$ROUTER_ID" = "x" ] && ROUTER_ID=$(head -1 /run/local-ipv4        2>/dev/null);

    # - IP local padrao
    # - IPv4
    [ "x$SOURCE_IPV4" = "x" ] && SOURCE_IPV4=$(head -1 /run/loopback-ipv4  2>/dev/null);
    [ "x$SOURCE_IPV4" = "x" ] && SOURCE_IPV4=$(head -1 /run/local-ipv4     2>/dev/null);
    # - IPv6
    [ "x$SOURCE_IPV6" = "x" ] && SOURCE_IPV6=$(head -1 /run/loopback-ipv6  2>/dev/null);
    [ "x$SOURCE_IPV6" = "x" ] && SOURCE_IPV6=$(head -1 /run/local-ipv6     2>/dev/null);


    # - RouterID versionado
    # - IPv4
    [ "x$ROUTER_ID4" = "x" ] && ROUTER_ID4="$ROUTER_ID";
    [ "x$ROUTER_ID4" = "x" ] && ROUTER_ID4=$(head -1 //run/loopback-ipv4         2>/dev/null);
    [ "x$ROUTER_ID4" = "x" ] && ROUTER_ID4=$(head -1 /run/router-id-ipv4-default 2>/dev/null);
    [ "x$ROUTER_ID4" = "x" ] && ROUTER_ID4=$(head -1 /run/local-ipv4             2>/dev/null);
    # - IPv6
    [ "x$ROUTER_ID6" = "x" ] && ROUTER_ID6=$(head -1 /run/loopback-ipv6          2>/dev/null);
    [ "x$ROUTER_ID6" = "x" ] && ROUTER_ID6=$(head -1 /run/router-id-ipv6-default 2>/dev/null);
    [ "x$ROUTER_ID6" = "x" ] && ROUTER_ID6=$(head -1 /run/local-ipv6             2>/dev/null);


    # Variaveis de SNMP
    [ "x$SNMP_ENABLE" = "x" ] && SNMP_ENABLE="yes";
    [ "$SNMP_ENABLE" = "no" ] || SNMP_ENABLE="yes";
    [ "x$SNMP_VIEW_ROUTES" = "x"   ] && SNMP_VIEW_ROUTES="no";
    [ "$SNMP_VIEW_ROUTES"  = "yes" ] || SNMP_VIEW_ROUTES="no";
    [ "x$SNMP_COMMUNITY"    = "x" ] && SNMP_COMMUNITY="frr-server";
    [ "x$SNMP_LOCATION"     = "x" ] && SNMP_LOCATION="datacenter";
    [ "x$SNMP_CONTACT"      = "x" ] && SNMP_CONTACT="Administrator";
    [ "x$SNMP_DESCRIPTION"  = "x" ] && SNMP_DESCRIPTION="FRR Server $FRR_TEMPLATE";
    [ "x$SNMP_PORT"         = "x" ] && SNMP_PORT="161";



# Exportar tudo para o ambiente
    export FIREWALL_ENABLE="$FIREWALL_ENABLE";
    export FIREWALL_PERMIT_PRIVATES="$FIREWALL_PERMIT_PRIVATES";
    export FIREWALL_PERMIT_NETWORKS="$FIREWALL_PERMIT_NETWORKS";

    export COUNTERS_ENABLE="$COUNTERS_ENABLE";

    export LOGSERVER_ENABLE="$LOGSERVER_ENABLE";
    export LOGSERVER_HOST="$LOGSERVER_HOST";
    export LOGSERVER_PORT="$LOGSERVER_PORT";

    export IGP_ALL_DEVS="$IGP_ALL_DEVS";
    export IGP_NETMODE="$IGP_NETMODE";
    export INTERFACE="$INTERFACE";
    export VLANS="$VLANS";

    export LAN_RESET="$LAN_RESET";
    export SUPERGW_ENABLE="$SUPERGW_ENABLE";

    export FIB_ENABLE="$FIB_ENABLE";

    export SERVICES="$SERVICES";

    export FRR_TEMPLATE="$FRR_TEMPLATE";
    export FRR_LOGFILE="$FRR_LOGFILE";

    export FRR_STATE_DIR="$FRR_STATE_DIR";
    export FRR_RUN_DIR="$FRR_RUN_DIR";

    export BGP_ASN="$BGP_ASN";

    export ROUTER_ID="$ROUTER_ID";
    export ROUTER_ID4="$ROUTER_ID4";
    export ROUTER_ID6="$ROUTER_ID6";

    export SOURCE_IPV4="$SOURCE_IPV4";
    export SOURCE_IPV6="$SOURCE_IPV6";

    export SNMP_ENABLE="$SNMP_ENABLE";
    export SNMP_VIEW_ROUTES="$SNMP_VIEW_ROUTES";
    export SNMP_COMMUNITY="$SNMP_COMMUNITY";
    export SNMP_LOCATION="$SNMP_LOCATION";
    export SNMP_CONTACT="$SNMP_CONTACT";
    export SNMP_DESCRIPTION="$SNMP_DESCRIPTION";
    export SNMP_PORT="$SNMP_PORT";


