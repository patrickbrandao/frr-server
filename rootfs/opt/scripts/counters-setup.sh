#!/bin/bash

# Criar regras nftables para sistema de contadores
#========================================================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|counters-start|$@"; echo "$now|counters-start|$@" >> $initlogfile; };
    _eval(){ _log "Running: $@"; out=$(eval "$@" 2>&1); sn="$?"; _log "Output[$sn]: $out"; };


    _log "Construindo regras de contadores";


    # Incluir config das variaveis de ambiente
    SYS_ENV="/opt/env.sh";
    _log "Incluindo variaveis de $SYS_ENV";
    [ -s "$SYS_ENV" ] && . $SYS_ENV;


    # Protocolos
    PROTO_LIST="
        bgpv4|ipv4|tcp:179
        bgpv6|ipv6|tcp:179

        ospfv4|ipv4|89
        ospfv6|ipv6|89

        ripv4|ipv4|udp:520
        ripv6|ipv6|udp:521

        isisv4|ipv4|124
        isisv6|ipv6|124

        fabricv4|ipv4|124
        fabricv6|ipv6|124

        pimv4|ipv4|103
        pimv6|ipv6|103

        ldpv4|ipv4|tcp:646
        ldpv6|ipv6|tcp:646

        ldpv4|ipv4|udp:646
        ldpv6|ipv6|udp:646

        eigrp|ipv4|88

        babel|ipv6|udp:6696

        bfdv4|ipv4|udp:3784
        bfdv6|ipv6|udp:3784

        bfdv4|ipv4|udp:4784
        bfdv6|ipv6|udp:4784

        vrrpv4|ipv4|112
        vrrpv6|ipv6|112
    ";


    # Criar tabelas personalizadas
    # - hook de input/output ipv4
    (
    	echo 'add   chain ip  mangle counters_input';
    	echo 'flush chain ip  mangle counters_input';
    	echo 'add   chain ip  mangle counters_output';
    	echo 'flush chain ip  mangle counters_output';
        echo "add rule ip  mangle INPUT  counter jump counters_input";
        echo "add rule ip  mangle OUTPUT counter jump counters_output";
    ) > /run/nftables.d/1001-chain-mangle-counters-ipv4.nft;

    # - hook de input/output ipv6
    (
    	echo 'add   chain ip6 mangle counters_input';
    	echo 'flush chain ip6 mangle counters_input';
    	echo 'add   chain ip6 mangle counters_output';
    	echo 'flush chain ip6 mangle counters_output';
        echo "add rule ip6 mangle INPUT  counter jump counters_input";
        echo "add rule ip6 mangle OUTPUT counter jump counters_output";
    ) > /run/nftables.d/1002-chain-mangle-counters-ipv6.nft;


    # Criar tabelas de ipv4
    V4CHAINS="";
    V6CHAINS="";
    for reg in $PROTO_LIST; do
        name=$(echo $reg  | cut -f1 -d'|');
        ipversion=$(echo $reg | cut -f2 -d'|');

        # Criar tabela para o servico
        [ "$ipversion" = "ipv4" ] && V4CHAINS="$V4CHAINS ${name}";
        [ "$ipversion" = "ipv6" ] && V6CHAINS="$V6CHAINS ${name}";
    done;


    # Sem repeticao
    V4CHAINS=$(for x in $V4CHAINS; do echo $x; done | sort -u);
    V6CHAINS=$(for x in $V6CHAINS; do echo $x; done | sort -u);


    # Criar chains
    # - IPv4
    for name in $V4CHAINS; do
        echo "add chain ip  mangle ${name}_input";
        echo "add chain ip  mangle ${name}_output";
        echo "flush chain ip mangle ${name}_input";
        echo "flush chain ip mangle ${name}_output";
    done > /run/nftables.d/1011-chain-mangle-counters-ipv4.nft;
    # - IPv6
    for name in $V6CHAINS; do
        echo "add chain ip6 mangle ${name}_input";
        echo "add chain ip6 mangle ${name}_output";
        echo "flush chain ip6 mangle ${name}_input";
        echo "flush chain ip6 mangle ${name}_output";
    done > /run/nftables.d/1012-chain-mangle-counters-ipv6.nft;


    # Criar tabela de clients e peers
    # - IPv4
    for name in $V4CHAINS; do
        echo "add set ip  mangle ${name}_clients { type ipv4_addr; timeout 1h; flags dynamic; }";
        echo "add set ip  mangle ${name}_peers   { type ipv4_addr; timeout 1h; flags dynamic; }";
    done > /run/nftables.d/1021-chain-mangle-counters-sessions-ipv4.nft;
    # - IPv6
    for name in $V6CHAINS; do
        echo "add set ip6 mangle ${name}_clients { type ipv6_addr; timeout 1h; flags dynamic; }";
        echo "add set ip6 mangle ${name}_peers   { type ipv6_addr; timeout 1h; flags dynamic; }";
    done > /run/nftables.d/1022-chain-mangle-counters-sessions-ipv6.nft;


    # Fazer captura de trafego para as tabelas
    for reg in $PROTO_LIST; do
        name=$(echo $reg  | cut -f1 -d'|');
        ipversion=$(echo $reg | cut -f2 -d'|');
        rule=$(echo $reg  | cut -f3 -d'|');

        # Analisar regra
        rproto=$(echo $rule | cut -f1 -d':');
        rport=$(echo $rule | cut -f2 -d':' -s);

        # Tipo de regra
        if [ "x$rport" = "x" ]; then
            # Apenas protocolo IP fundamental
			# - ipv4
			[ "$ipversion" = "ipv4" ] && echo "add rule ip  mangle counters_input  ip  protocol $rproto counter jump ${name}_input";
			[ "$ipversion" = "ipv4" ] && echo "add rule ip  mangle counters_output ip  protocol $rproto counter jump ${name}_output";
			# - ipv6
			[ "$ipversion" = "ipv6" ] && echo "add rule ip6 mangle counters_input  ip6 nexthdr $rproto  counter jump ${name}_input";
			[ "$ipversion" = "ipv6" ] && echo "add rule ip6 mangle counters_output ip6 nexthdr $rproto  counter jump ${name}_output";
        else
            # Protocolo parseavel (TCP/UDP)
			# - ipv4
			[ "$ipversion" = "ipv4" ] && echo "add rule ip  mangle counters_input  $rproto dport $rport counter jump ${name}_input";
			[ "$ipversion" = "ipv4" ] && echo "add rule ip  mangle counters_output $rproto dport $rport counter jump ${name}_output";
			# - ipv6
			[ "$ipversion" = "ipv6" ] && echo "add rule ip6 mangle counters_input  $rproto dport $rport counter jump ${name}_input";
			[ "$ipversion" = "ipv6" ] && echo "add rule ip6 mangle counters_output $rproto dport $rport  counter jump ${name}_output";
        fi;
    done > /run/nftables.d/1030-chain-mangle-counters-jumps.nft;


    # Criar regra de aprendizado de clientes
    # - IPv4
    for name in $V4CHAINS; do
        echo "add rule ip  mangle ${name}_input add @${name}_clients { ip saddr } counter";
        echo "add rule ip  mangle ${name}_input set update ip saddr timeout 0s @${name}_clients counter";
    done > /run/nftables.d/1041-chain-mangle-learning-ipv4.nft;
    # - IPv6
    for name in $V6CHAINS; do
        echo "add rule ip6 mangle ${name}_input add @${name}_clients { ip6 saddr } counter";
        echo "add rule ip6 mangle ${name}_input set update ip6 saddr timeout 0s @${name}_clients counter";
    done > /run/nftables.d/1042-chain-mangle-learning-ipv6.nft;


    # Criar regra de confirmacao de sessao (peers)
    # - IPv4
    for name in $V4CHAINS; do
        echo "add rule ip  mangle ${name}_output ip daddr @${name}_clients add @${name}_peers { ip daddr } counter accept";
    done > /run/nftables.d/1051-chain-mangle-register-ipv4.nft;
    # - IPv6
    for name in $V6CHAINS; do
        echo "add rule ip6 mangle ${name}_output ip6 daddr @${name}_clients add @${name}_peers { ip6 daddr } counter accept";
    done > /run/nftables.d/1052-chain-mangle-register-ipv6.nft;


    _log "Setup de contadores concluido";


exit 0;



