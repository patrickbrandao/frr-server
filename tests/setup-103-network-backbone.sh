#!/bin/bash

# Criar - Diferentes redes de origem para simulacao (OSPF, BABEL, eBGP/iBGP, ...)

# Rede BACKBONE
    # - Ja existe
    [ -d /sys/class/net/br-backbone ] && exit 0;

    # - Criar
    docker network create \
        -d bridge \
        \
        -o "com.docker.network.bridge.name"="br-backbone" \
        -o "com.docker.network.bridge.enable_icc"="true" \
        -o "com.docker.network.driver.mtu"="65495" \
        \
        --subnet 10.142.0.0/16 --gateway 10.142.255.254 \
        \
        --ipv6 \
        --subnet=2001:db8:10:142::/64 \
        --gateway=2001:db8:10:142::254 \
        \
        backbone;
