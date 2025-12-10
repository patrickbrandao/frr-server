#!/bin/bash

# NFTABLES para firewall e contador
#========================================================================

    # Retirar defaults
    rm -f /etc/nftables.conf 2>/dev/null;
    rm -f /etc/nftables.nft  2>/dev/null;

    # Trabalhar incluido arquivos externos
    (
        echo '#!/usr/sbin/nft -f';
        echo;
        echo 'flush ruleset';
        echo 'include "/run/nftables.d/*.conf"';
        echo 'include "/run/nftables.d/*.nft"';
        echo;
    ) > /etc/nftables.conf;

    # Unificar diferentes distribuicoes
    ln -sf /etc/nftables.conf /etc/nftables.nft;


exit 0;

