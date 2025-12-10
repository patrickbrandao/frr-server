#!/bin/bash

# Iniciar firewall para contador de trafego
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|counters-setup: $@"; echo "$now|counters-setup: $@" >> $initlogfile; };

    _log "Iniciando counters";
    [ "$COUNTERS_ENABLE" = "yes" ] || {
        _log "Contador desativado";
        exit 0;
    };

    # Setup dos contadores
    _log "Acionando construcao de contadores";
    /opt/scripts/counters-setup.sh;


exit 0;

