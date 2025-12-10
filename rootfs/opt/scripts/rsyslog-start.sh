#!/bin/bash

# Script para iniciar servidor de logs
#========================================================================================================

    # Variaveis
    config=/run/rsyslog/rsyslogd.conf
    pidfile=/run/rsyslog/rsyslogd.pid

    # Impedir conflito de PID
    [ -f "$pidfile" ] && rm -f "$pidfile" 2>/dev/null

    # Garantir config default
    [ -f "$config" ] || cp "/etc/rsyslog.conf" "$config"

    # Rodar
    exec /usr/sbin/rsyslogd -n -f "$config" -i "$pidfile"

