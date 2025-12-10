#!/bin/bash

# Executar servico de firewall
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|nftables-run: $@"; echo "$now|nftables-run: $@" >> $initlogfile; };


    # Ignorar se nao houver servico que va usar o firewall
    if [ "$FIREWALL_ENABLE" = "yes" -o "$COUNTERS_ENABLE" = "yes" ]; then
        # firewall ativo
        _log "Firewall necessario, rodando"
    else
        # sem necessidade
        _log "Firewall desnecessario, sem servicos vinculados."
        exit 0;
    fi;


    # Rodar
    cd /run/nftables.d;
    # - CONFs
    for nft_item in *.conf; do
        _log "Executando conf: $nft_item";
        nft -f $nft_item || { _log "Falhou em $nft_item"; };
    done;

    # - NFT
    for nft_item in *.nft; do
        _log "Executando nft: $nft_item";
        nft -f $nft_item || { _log "Falhou em $nft_item"; };
    done;


exit 0;

