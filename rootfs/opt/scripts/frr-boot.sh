#!/bin/bash

# Rodar FRR - Zebra e servicos
#========================================================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|frr-boot|$@"; echo "$now|frr-boot|$@" >> $initlogfile; };


    # Incluir config das variaveis de ambiente
    SYS_ENV="/opt/env.sh";
    _log "Incluindo variaveis de $SYS_ENV";
    [ -s "$SYS_ENV" ] && . $SYS_ENV;


    # Obter lista de servicos
    SERVICE_LIST=$(cat /data/frr/services 2>/dev/null);
    if [ "x$SERVICE_LIST" = "x" ]; then
        SERVICE_LIST="bgpd ripd ripngd ospfd ospf6d babeld pbrd bfdd";
    fi;


    # Rodar
    ZCMD="exec /usr/lib/frr/watchfrr zebra staticd $SERVICE_LIST";
    _log "Executando: $ZCMD";
    eval $ZCMD;


    # Sleep de erro no exec
    sleep 5;


exit 0;

