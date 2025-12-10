#!/bin/bash

# Adicionar super gateway para nao requerer rotas igp
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|supergw: $@"; echo "$now|supergw: $@" >> $initlogfile; };
    _eval(){ _log "Running: $@"; out=$(eval "$@" 2>&1); sn="$?"; _log "Output [$@] = stdno[$sn] stdout[$out]"; };


    # Detectar gateway padrao IPv4
    GATEWAY_IPV4_FOUND=no;
    GATEWAY_IPV4_ADDR=$(ip -o -4 ro get 1.2.3.4 | sed 's#via.#|#g'| cut -f2 -d'|' | awk '{print $1}');
    if [ "x$GATEWAY_IPV4_ADDR" = "x" ]; then
        _log "Gateway IPv4 nao detectado, ignorando SuperGateway";
    else
        _log "Gateway IPv4: $GATEWAY_IPV4_ADDR";
        GATEWAY_IPV4_FOUND=yes;
        echo "$GATEWAY_IPV4_ADDR" > /run/gateway-ipv4;
    fi;


    # Detectar gateway padrao IPv6
    GATEWAY_IPV6_FOUND=no;
    GATEWAY_IPV6_ADDR=$(ip -o -6 ro get 2001::1 | sed 's#via.#|#g'| cut -f2 -d'|' | awk '{print $1}');
    if [ "x$GATEWAY_IPV6_ADDR" = "x" ]; then
        _log "Gateway IPv6 nao detectado, ignorando SuperGateway";
    else
        _log "Gateway IPv6: $GATEWAY_IPV6_ADDR";
        GATEWAY_IPV6_FOUND=yes;
        echo "$GATEWAY_IPV6_ADDR" > /run/gateway-ipv6;
    fi;


    # Inserir?
    if [ "$SUPERGW_ENABLE" = "yes" ]; then
        _log "SuperGateway ativo, inserindo rota estatica";
        # - IPv4
        if [ "$GATEWAY_IPV4_FOUND" "yes" ]; then
            _eval "ip -4 route add   0.0.0.0/1 via $GATEWAY_IPV4_ADDR proto static metric 254";
            _eval "ip -4 route add 128.0.0.0/1 via $GATEWAY_IPV4_ADDR proto static metric 254";
        else
            _log "SuperGateway IPv4 ignorado, sem gateway.";
        fi;
        # - IPv6
        if [ "$GATEWAY_IPV6_FOUND" "yes" ]; then
            #_eval "ip -6 route add 2000::/3 via $GATEWAY_IPV6_ADDR proto static metric 254";
            _eval "ip -6 route add     ::/1 via $GATEWAY_IPV6_ADDR proto static metric 254";
            _eval "ip -6 route add 8000::/1 via $GATEWAY_IPV6_ADDR proto static metric 254";
        else
            _log "SuperGateway IPv6 ignorado, sem gateway.";
        fi;
    else
        _log "SuperGateway desativado.";
    fi;


exit 0;

