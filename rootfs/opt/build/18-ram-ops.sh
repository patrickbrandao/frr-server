#!/bin/bash

# Operacoes na RAM (tmpfs)
#========================================================================

    # Pasta TMP obrigatoriamente em tmpfs /run
    rm -rf /var/tmp 2>/dev/null;
    ln -sf /run/tmp /var/tmp;

    # Logs no volume
    rm -rf /var/log 2>/dev/null;
    ln -sf /data/logs /var/log;

exit 0;
