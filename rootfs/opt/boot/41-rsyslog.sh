#!/bin/bash

# Preparacao de logs
#========================================================================

    # Diretorio de logs
    mkdir -p /data/logs;
    mkdir -p /run/rsyslog;

    # Arquivos de log
    touch /data/logs/auth.log;
    touch /data/logs/cron.log;
    touch /data/logs/kern.log;
    touch /data/logs/mail.log;
    touch /data/logs/user.log;
    touch /data/logs/syslog.log;

    chown root:root /data/logs/auth.log;
    chown root:root /data/logs/cron.log;
    chown root:root /data/logs/kern.log;
    chown root:adm  /data/logs/mail.log;
    chown root:adm  /data/logs/user.log;
    chown root:adm  /data/logs/syslog.log;

    # Config padrao
    cp /etc/rsyslog.conf /run/rsyslog/rsyslogd.conf;

exit 0;

