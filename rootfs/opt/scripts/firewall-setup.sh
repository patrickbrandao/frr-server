#!/bin/bash

# Criar regras nftables para protecao dos servicos
#========================================================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|firewall-start|$@"; echo "$now|firewall-start|$@" >> $initlogfile; };
    _eval(){ _log "Running: $@"; out=$(eval "$@" 2>&1); sn="$?"; _log "Output[$sn]: $out"; };


    _log "Construindo regras de firewall";


    # Incluir config das variaveis de ambiente
    SYS_ENV="/opt/env.sh";
    _log "Incluindo variaveis de $SYS_ENV";
    [ -s "$SYS_ENV" ] && . $SYS_ENV;


    # Criar tabelas personalizadas
    # - hook de input/output ipv4
    (
        echo 'add   chain ip  filter firewall_input';
        echo 'flush chain ip  filter firewall_input';
        echo 'add   chain ip  filter firewall_output';
        echo 'flush chain ip  filter firewall_output';
        echo "add rule ip  filter INPUT  counter jump firewall_input";
        echo "add rule ip  filter OUTPUT counter jump firewall_output";
    ) > /run/nftables.d/2001-chain-filter-firewall-ipv4.nft;
    # - hook de input/output ipv6
    (
        echo 'add   chain ip6 filter firewall_input';
        echo 'flush chain ip6 filter firewall_input';
        echo 'add   chain ip6 filter firewall_output';
        echo 'flush chain ip6 filter firewall_output';
        echo "add rule ip6 filter INPUT  counter jump firewall_input";
        echo "add rule ip6 filter OUTPUT counter jump firewall_output";
    ) > /run/nftables.d/2002-chain-filter-firewall-ipv6.nft;


    # Permissoes estaticas
    # - Permitir loopback - ipv4
    (
        echo 'add rule ip filter firewall_input ip saddr 127.0.0.0/8 counter return';
        echo 'add rule ip filter firewall_input ip daddr 127.0.0.0/8 counter return';
    ) > /run/nftables.d/2011-chain-filter-loopback-ipv4.nft;
    # - Permitir loopback - ipv6
    (
        echo 'add rule ip6 filter firewall_input ip6 saddr ::1/128 counter return';
        echo 'add rule ip6 filter firewall_input ip6 daddr ::1/128 counter return';
    ) > /run/nftables.d/2012-chain-filter-loopback-ipv6.nft;



    # Permitir rede local
    # - Redes locais IPv4
    locals_ipv4=$(ip -4 route show | egrep -v '(default|static)' | awk '{print $1}');
    for net in $locals_ipv4; do
        echo "add rule ip filter firewall_input ip saddr $net counter return";
    done > /run/nftables.d/2021-chain-filter-locals-ipv4.nft;

    # - Redes locais IPv6
    locals_ipv6=$(ip -6 route show | egrep -v '(default|static)' | awk '{print $1}');
    for net in $locals_ipv6; do
        echo "add rule ip6 filter firewall_input ip6 saddr $net counter return";
    done > /run/nftables.d/2022-chain-filter-locals-ipv6.nft;



    # - permitir redes privadas
    if [ "$FIREWALL_PERMIT_PRIVATES" = "yes" ]; then
        _log "Redes privadas autorizadas";
        # Privados IPv4
        PRIVATES_IPV4="
            10.0.0.0/8
            169.254.0.0/16
            172.16.0.0/12
            192.0.0.0/24
            192.0.2.0/24
            192.88.99.0/24
            192.168.0.0/16
            198.18.0.0/15
            198.51.100.0/24
            203.0.113.0/24
            224.0.0.0/4
            240.0.0.0/4
        ";
        for net in $PRIVATES_IPV4; do
            echo "add rule ip filter firewall_input ip saddr $net counter return";
        done > /run/nftables.d/2031-chain-filter-privates-ipv4.nft;

        # Privados IPv6
        PRIVATES_IPV6="
            ::/3
            2001:db8::/32
            4000::/2
            8000::/1
        ";
        for net in $PRIVATES_IPV6; do
            echo "add rule ip6 filter firewall_input ip6 saddr $net counter return";
        done > /run/nftables.d/2032-chain-filter-privates-ipv6.nft;
    else
        _log "Redes privadas NAO autorizadas";
    fi;




    # redes permitidas pelo administrador
    if [ "x$FIREWALL_PERMIT_NETWORKS" = "x" ]; then
        _log "Nenhuma rede permitida foi configurada";
    else
        # Analisar redes autorizadas e separar v4 de v6
        ALLOWEDS_IPV4="";
        ALLOWEDS_IPV6="";
        tmp=$(echo "$FIREWALL_PERMIT_NETWORKS" | sed 's#,# #g; s#|# #g; s#;# #g;');
        _log "Autorizando redes permitidas: $tmp";
        for word in $tmp; do
            echo "$word" | egrep -q ':' 2>/dev/null 1>/dev/null;
            stdno="$?";
            if [ "$stdno" = "0" ]; then
                #echo "IPv6: $word";
                _log "Autorizando IPv4: $word";
                ALLOWEDS_IPV6="$ALLOWEDS_IPV6 $word"
                #ip6tables -t filter -A firewall_input -s $word -j RETURN;
            else
                #echo "IPv4: $word";
                _log "Autorizando IPv6: $word";
                ALLOWEDS_IPV4="$ALLOWEDS_IPV4 $word"
                #iptables -t filter -A firewall_input -s $word -j RETURN;
            fi;
        done;

        # trim
        ALLOWEDS_IPV4=$(echo $ALLOWEDS_IPV4);
        ALLOWEDS_IPV6=$(echo $ALLOWEDS_IPV6);

        # Autorizar IPv4
        if [ "x$ALLOWEDS_IPV4" = "x" ]; then
            _log "Nenhuma rede IPv4 autorizada foi declarada";
        else
            _log "Redes IPv4 autorizadas: $ALLOWEDS_IPV4";
            for net in $ALLOWEDS_IPV4; do
                echo "add rule ip filter firewall_input ip saddr $net counter return";
            done > /run/nftables.d/2041-chain-filter-allowed-ipv4.nft;
        fi;

        # Autorizar IPv6
        if [ "x$ALLOWEDS_IPV6" = "x" ]; then
            _log "Nenhuma rede IPv6 autorizada foi declarada";
        else
            _log "Redes IPv6 autorizadas: $ALLOWEDS_IPV6";
            for net in $ALLOWEDS_IPV6; do
                echo "add rule ip6 filter firewall_input ip6 saddr $net counter return";
            done > /run/nftables.d/2042-chain-filter-allowed-ipv6.nft;
        fi;
    fi;

    # Drop no resto
    echo "add rule ip  filter firewall_input counter drop" > /run/nftables.d/9901-chain-filter-drop-ipv4.nft;
    echo "add rule ip6 filter firewall_input counter drop" > /run/nftables.d/9902-chain-filter-drop-ipv6.nft;

    _log "Setup de firewall concluido";


exit 0;




