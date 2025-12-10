#!/bin/bash

# Detectar IP de origem padrao
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|local-src-addr: $@"; echo "$now|local-src-addr: $@" >> $initlogfile; };

    # - Origem padrao IPv4
    LOCAL_IPV4_ADDR=$(ip -o -4 ro get 1.2.3.4 | sed 's#src.#|#g'| cut -f2 -d'|' | awk '{print $1}');
    if [ "x$LOCAL_IPV4_ADDR" = "x" ]; then
        _log "IP de origem IPv4 local nao detectado";
    else
        _log "IP de origem IPv4 local: $LOCAL_IPV4_ADDR";
        echo "$LOCAL_IPV4_ADDR" > /run/local-ipv4;
    fi;

    # - Origem padrao IPv6
    LOCAL_IPV6_ADDR=$(ip -o -6 ro get 2001::1 | sed 's#src.#|#g'| cut -f2 -d'|' | awk '{print $1}');
    if [ "x$LOCAL_IPV6_ADDR" = "x" ]; then
        _log "IP de origem IPv6 local nao detectado";
    else
        _log "IP de origem IPv6 local: $LOCAL_IPV6_ADDR";
        echo "$LOCAL_IPV6_ADDR" > /run/local-ipv6;
    fi;

    # Na ausencia de um ip de origem ipv4 local, peguar
    # o primeiro ipv4 presente para ser o router-id padrao
    # de emergencia
    if [ "x$LOCAL_IPV4_ADDR" = "x" ]; then
        LOCAL_IPV4_ADDR=$(ip -4 addr show | egrep -v '127.0.0.1' | egrep 'inet' | head -1 | awk '{print $2}' | cut -f1 -d/);
        if [ "x$LOCAL_IPV4_ADDR" = "x" ]; then
            _log "Curioso, container sem IP...";
        else
            _log "IP de origem IPv4 local fallback: $LOCAL_IPV4_ADDR";
            echo "$LOCAL_IPV4_ADDR" > /run/local-ipv4;
        fi;
    fi;


exit 0;

