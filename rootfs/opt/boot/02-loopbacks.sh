#!/bin/bash

# Processar lista de loopbacks
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|loopback: $@"; echo "$now|loopback: $@" >> $initlogfile; };
    _eval(){ _log "Running: $@"; out=$(eval "$@" 2>&1); sn="$?"; _log "Output [$@] = stdno[$sn] stdout[$out]"; };

    # Coletar definicoes de loopbacks
    LOLIST="$LOOPBACK $LO $LO4 $LO6 $LOV4 $LOIPV4 $LOIPV6 $LOV6 $LOOPBACKS $LOOPBACK_IPV4 $LOOPBACK_IPV6 $LOOPBACK4 $LOOPBACK6  $LOOPBACKV4 $LOOPBACKV6";
    LOLIST=$(echo $LOLIST | sed 's#,# #g');
    LOLIST=$(echo $LOLIST);
    LOLIST=$(for x in $LOLIST; do echo $x; done | sort -u);

    _log "Iniciando config de loopbacks";

    # Sem definicao de loopbacks, ignorar
    [ "x$LOLIST" = "x" ] && {
        _log "Nenhuma loopback definida";
        exit 0;
    };

    # Processar lista para garantir /32 ou /128
    _log "Enderecos de loopback: $LOLIST";
    DEFAULT_ROUTER_ID4="";
    DEFAULT_ROUTER_ID6="";
    for loaddr in $LOLIST; do
        addr=$(echo $loaddr | cut -f1 -d/);
        ipv=4; plen=32;
        echo "$addr" | egrep -q ':' && { ipv=6; plen=128; };
        # atribuir na LO
        _log "Registrando loopback [IPv$ipv]: $addr";
        _eval "ip -$ipv addr add $addr/$plen dev lo";
        # Detectar primeira loopback como router-id padrao
        # - IPv4
        [ "$ipv" = "4" -a "x$DEFAULT_ROUTER_ID4" = "x" ] && {
            DEFAULT_ROUTER_ID4="$addr";
        };
        # - IPv6
        [ "$ipv" = "6" -a "x$DEFAULT_ROUTER_ID6" = "x" ] && {
            DEFAULT_ROUTER_ID6="$addr";
        };
    done;

    # Gravar router-id padrao
    # - IPv4
    [ "x$DEFAULT_ROUTER_ID4" = "x" ] || {
        _log "Default IPv4 Router-ID: $DEFAULT_ROUTER_ID4";
        echo "$DEFAULT_ROUTER_ID4" > /run/loopback-ipv4;
        echo "$DEFAULT_ROUTER_ID4" > /run/router-id-default;
        echo "$DEFAULT_ROUTER_ID4" > /run/router-id-ipv4-default;
    };
    # - IPv6
    [ "x$DEFAULT_ROUTER_ID6" = "x" ] || {
        _log "Default IPv6 Router-ID: $DEFAULT_ROUTER_ID6";
        echo "$DEFAULT_ROUTER_ID6" > /run/loopback-ipv6;
        echo "$DEFAULT_ROUTER_ID6" > /run/router-id-ipv6-default;
    };


    _log "Registro de loopbacks concluido";


exit 0;


