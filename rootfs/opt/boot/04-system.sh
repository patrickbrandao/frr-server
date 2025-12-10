#!/bin/bash

# Alteracoes no sistema
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|loopback: $@"; echo "$now|loopback: $@" >> $initlogfile; };
    _eval(){ _log "Running: $@"; out=$(eval "$@" 2>&1); sn="$?"; _log "Output [$@] = stdno[$sn] stdout[$out]"; };

    _log "Alteracoes no sistema";

    # History do bash no volume
    DHISTORY="/data/.bash_history";
    BHISTORY="/root/.bash_history";
    [ -L "$BHISTORY" ] || {
        _log "Movendo history do bash para o volume";
        # nao e' link ou nao existe, mover
        rm -f "$BHISTORY";
        ln -sf $DHISTORY $BHISTORY;
        touch $DHISTORY;
        chown root:root $DHISTORY;
        chmod 0600 $DHISTORY;
    };


exit 0;

