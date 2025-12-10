#!/bin/bash

# Politica de rotacao de logs acumulativos
#========================================================================

    # Rotacao de logs do container
    (
        echo '/data/logs/*.log {';
        echo '    daily';
        echo '    missingok';
        echo '    rotate 14';
        echo '    compress';
        echo '    delaycompress';
        echo '    notifempty';
        echo '    create 640 root adm';
        echo '    sharedscripts';
        echo '    prerotate';
        echo '            /opt/scripts/log-rotate-pre.sh';
        echo '    endscript';
        echo '    postrotate';
        echo '            /opt/scripts/log-rotate-pos.sh';
        echo '    endscript';
        echo '}';
    ) > /etc/logrotate.d/datalogs;

    # Rotacao de logs do FRR
    # (
    #     echo '/var/log/frr/*.log {';
    #     echo '    size 500k';
    #     echo '    sharedscripts';
    #     echo '    missingok';
    #     echo '    compress';
    #     echo '    rotate 14';
    #     echo '    create 0640 frr frr';
    #     echo '';
    #     echo '    postrotate';
    #     echo '        pid=$(lsof -t -a -c /syslog/ /var/log/frr/* 2>/dev/null)';
    #     echo '        if [ -n "$pid" ]';
    #     echo '        then # using syslog';
    #     echo '             kill -HUP $pid';
    #     echo '        fi';
    #     echo '        # in case using file logging; if switching back and forth';
    #     echo '        # between file and syslog, rsyslogd might still have file';
    #     echo '        # open, as well as the daemons, so always signal the daemons.';
    #     echo '        # It's safe, a NOP if (only) syslog is being used.';
    #     echo '        for i in babeld bgpd eigrpd isisd ldpd nhrpd ospf6d ospfd sharpd \';
    #     echo '            pimd pim6d ripd ripngd zebra pathd pbrd staticd bfdd fabricd vrrpd; do';
    #     echo '            if [ -e /var/run/frr/$i.pid ] ; then';
    #     echo '                pids="$pids $(cat /var/run/frr/$i.pid)"';
    #     echo '            fi';
    #     echo '        done';
    #     echo '        [ -n "$pids" ] && kill -USR1 $pids || true';
    #     echo '    endscript';
    #     echo '}';
    # ) > /etc/logrotate.d/frr 

exit 0;

