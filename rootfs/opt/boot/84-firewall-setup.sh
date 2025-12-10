#!/bin/bash

# Construir firewall personalizado
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|firewall-setup-boot: $@"; echo "$now|firewall-setup-boot: $@" >> $initlogfile; };

    _log "Iniciando firewall";
    [ "$FIREWALL_ENABLE" = "yes" ] || {
        _log "Firewall desativado";
        exit 0;
    };

    # Setup de firewall
    _log "Acionando construcao de firewall";
    /opt/scripts/firewall-setup.sh;

exit 0;

