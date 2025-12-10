#!/bin/bash

EXEC_CMD="$@"

# Funcoes
#========================================================================================================

    nowdts=$(date '+%Y-%m-%d-%H%M%S');
    initlogfile="/data/logs/init.log";
    lastlogfile="/data/logs/last-$nowdts.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|$@"; echo "$now|$@" >> $initlogfile; };
    _eval(){ _log "Running: $@"; out=$(eval "$@" 2>&1); sn="$?"; _log "Output[$sn]: $out"; };


#========================================================================================================


    # Scripts de ponto de entrada
    _init_boot_scripts(){
        _log "BOOT-SCRIPTS-INIT";
        cd /opt/boot || {
            _log "BOOT-SCRIPTS-FAIL: directory /opt/boot not found";
            return 9;
        }
        for escript in *.sh; do
            _log "Entrypoint script: start [$escript]";
            ./$escript;
            sn="$?";
            _log "Entrypoint script: stdno [$escript] = $sn";
        done;
        _log "BOOT-SCRIPTS-END";
    };


#========================================================================================================

    # Preparacao fundamental
    mkdir -p /data;
    mkdir -p /data/logs;

    # Pasta de arquivos temporarios
    mkdir -p /run/tmp;
    mkdir -p /run/lock;


#========================================================================================================

    # Variaveis de ambiente exportadas para scripts isolados

    # Variaveis de ambiente normalizadas
    SETUP_ENV="/opt/env.sh";
    [ -f "$SETUP_ENV" ] && . $SETUP_ENV;

    # Gravar variaveis de ambiente na config
    # para scripts que rodam sem herdar variaveis de ambiente
    BOOT_ENV="/run/env.sh";
    (
        env | egrep '(LOOP|FIREWALL|COUNTERS|LOG|SUPER|FIB|SERVICES|BGP|TEMPLATE|ROUTER|FRR|SOURCE|SNMP|VLANS|INTERFACE|IGP|RESET)' | while read line; do
            KN=$(echo "$line" | cut -f1 -d=);
            KV=$(echo "$line" | cut -f2 -d=);
            echo "export $KN='$KV';";
        done;
    ) > $BOOT_ENV;


#========================================================================================================

    # Limpar logs do ultimo boot
    cp $initlogfile $lastlogfile;
    echo -n > $initlogfile;

    # INICIAR:
    _log "Start entrypoint [$0 $@] cmd $EXEC_CMD";

    # Executar scripts de entrypoint
    _log "Start boot scripts";
    _init_boot_scripts;

    # Rodar CMD
    if [ "x$EXEC_CMD" = "x" ]; then
        _log "Start default CMD: [sleep 252288000]";
        exec "sleep" "252288000";
        stdno="$?";
    else
        FULLCMD="exec $EXEC_CMD";
        _log "Start CMD: [$EXEC_CMD] [$FULLCMD]";
        eval $FULLCMD;
        stdno="$?";
    fi
    _log "Entrypoint end, stdno=$stdno";

exit $stdno;

