#!/bin/bash

# Servico de firewall - estrutura basica
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|nftables-boot: $@"; echo "$now|nftables-boot: $@" >> $initlogfile; };


    # Ignorar se nao houver servico que va usar o firewall
    if [ "$FIREWALL_ENABLE" = "yes" -o "$COUNTERS_ENABLE" = "yes" ]; then
        # firewall ativo
        _log "Firewall ativado, configurando"
    else
        # sem necessidade
        _log "Firewall desnecessario, sem servicos vinculados."
        exit 0;
    fi;


    # Pasta de regras em ordem
    mkdir -p /run/nftables.d;


    # Arquivos de boot das tabelas
    echo "create table ip raw"     > /run/nftables.d/0001-table-ipv4-raw.conf;
    echo "create table ip mangle"  > /run/nftables.d/0002-table-ipv4-mangle.conf;
    echo "create table ip filter"  > /run/nftables.d/0003-table-ipv4-filter.conf;
    #echo "create table ip nat"     > /run/nftables.d/0004-table-ipv4-nat.conf;

    echo "create table ip6 raw"    > /run/nftables.d/0011-table-ipv6-raw.conf;
    echo "create table ip6 mangle" > /run/nftables.d/0012-table-ipv6-mangle.conf;
    echo "create table ip6 filter" > /run/nftables.d/0013-table-ipv6-filter.conf;
    #echo "create table ip6 nat"    > /run/nftables.d/0014-table-ipv6-nat.conf;


    #======================================================== IPv4
    #------------ RAW
    (
      echo "create chain ip raw PREROUTING {";
      echo "    type filter hook prerouting priority raw;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0021-chain-ipv4-raw-prerouting.conf;

    (
      echo "create chain ip raw OUTPUT {";
      echo "    type filter hook output priority raw;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0022-chain-ipv4-raw-output.conf;


    #------------ MANGLE
    (
      echo "create chain ip mangle PREROUTING {";
      echo "    type filter hook prerouting priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0023-chain-ipv4-mangle-prerouting.conf;

    (
      echo "create chain ip mangle POSTROUTING {";
      echo "    type filter hook postrouting priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0024-chain-ipv4-mangle-postrouting.conf;

    (
      echo "create chain ip mangle FORWARD {";
      echo "    type filter hook forward priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0025-chain-ipv4-mangle-forward.conf;

    (
      echo "create chain ip mangle INPUT {";
      echo "    type filter hook input priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0026-chain-ipv4-mangle-input.conf;

    (
      echo "create chain ip mangle OUTPUT {";
      echo "    type route hook output priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0027-chain-ipv4-mangle-output.conf;

    #------------ FILTER
    (
      echo "create chain ip filter FORWARD {";
      echo "    type filter hook forward priority filter;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0028-chain-ipv4-filter-forward.conf;

    (
      echo "create chain ip filter INPUT {";
      echo "    type filter hook input priority filter;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0029-chain-ipv4-filter-input.conf;

    (
      echo "create chain ip filter OUTPUT {";
      echo "    type filter hook output priority filter;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0030-chain-ipv4-filter-output.conf;


    #------------ NAT
    # (
    #   echo "create chain ip nat PREROUTING {";
    #   echo "    type nat hook prerouting priority dstnat;";
    #   echo "    policy accept;";
    #   echo "}";
    # ) > /run/nftables.d/0031-chain-ipv4-nat-prerouting.conf;

    # (
    #   echo "create chain ip nat INPUT {";
    #   echo "    type nat hook input priority 100;";
    #   echo "    policy accept;";
    #   echo "}";
    # ) > /run/nftables.d/0032-chain-ipv4-nat-input.conf;
        
    # (
    #   echo "create chain ip nat OUTPUT {";
    #   echo "    type nat hook output priority -100;";
    #   echo "    policy accept;";
    #   echo "}";
    # ) > /run/nftables.d/0033-chain-ipv4-nat-output.conf;

    # (
    #   echo "create chain ip nat POSTROUTING {";
    #   echo "    type nat hook postrouting priority srcnat;";
    #   echo "    policy accept;";
    #   echo "}";
    # ) > /run/nftables.d/0034-chain-ipv4-nat-postrouting.conf;



    #======================================================== IPv6
    #------------ RAW
    (
      echo "create chain ip6 raw PREROUTING {";
      echo "    type filter hook prerouting priority raw;";
      echo "    policy accept";
      echo "}";
    ) > /run/nftables.d/0041-chain-ipv6-raw-prerouting.conf;

    (
      echo "create chain ip6 raw OUTPUT {";
      echo "    type filter hook output priority raw;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0042-chain-ipv6-raw-postrouting.conf;

    #------------ MANGLE
    (
      echo "create chain ip6 mangle PREROUTING {";
      echo "    type filter hook prerouting priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0043-chain-ipv6-mangle-prerouting.conf;

    (
      echo "create chain ip6 mangle POSTROUTING {";
      echo "    type filter hook postrouting priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0044-chain-ipv6-mangle-postrouting.conf;

    (
      echo "create chain ip6 mangle FORWARD {";
      echo "    type filter hook forward priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0045-chain-ipv6-mangle-forward.conf;

    (
      echo "create chain ip6 mangle INPUT {";
      echo "    type filter hook input priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0046-chain-ipv6-mangle-input.conf;

    (
      echo "create chain ip6 mangle OUTPUT {";
      echo "    type route hook output priority mangle;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0047-chain-ipv6-mangle-output.conf;

    #------------ FILTER
    (
      echo "create chain ip6 filter FORWARD {";
      echo "    type filter hook forward priority filter;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0048-chain-ipv6-filter-forward.conf;

    (
      echo "create chain ip6 filter INPUT {";
      echo "    type filter hook input priority filter;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0049-chain-ipv6-filter-input.conf;

    (
      echo "create chain ip6 filter OUTPUT {";
      echo "    type filter hook output priority filter;";
      echo "    policy accept;";
      echo "}";
    ) > /run/nftables.d/0050-chain-ipv6-filter-output.conf;


    #------------ NAT
    # (
    #   echo "create chain ip6 nat PREROUTING {";
    #   echo "    type nat hook prerouting priority dstnat;";
    #   echo "    policy accept;";
    #   echo "}";
    # ) > /run/nftables.d/0051-chain-ipv6-filter-prerouting.conf;
    # (
    #   echo "create chain ip6 nat POSTROUTING {";
    #   echo "    type nat hook postrouting priority srcnat;";
    #   echo "    policy accept;";
    #   echo "}";
    # ) > /run/nftables.d/0051-chain-ipv6-filter-postrouting.conf;
    # (
    #   echo "create chain ip6 nat    OUTPUT {";
    #   echo "    type nat hook output priority -100;";
    #   echo "    policy accept;";
    #   echo "}";
    # ) > /run/nftables.d/0052-chain-ipv6-filter-output.conf;



exit 0;


