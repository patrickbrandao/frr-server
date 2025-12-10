#!/bin/bash

# SupervidorD
#========================================================================

    # Orientar logs para pasta do volume
    echo "# Ajustes da config do supervisor";
    sed -i "s#^logfile.*#logfile=/data/logs/supervisord.log#g"    /etc/supervisor/supervisord.conf;
    sed -i "s#^pidfile.*#pidfile=/run/supervisord.pid#g"          /etc/supervisor/supervisord.conf;
    sed -i "s#^childlogdir.*#childlogdir=/data/logs#g"            /etc/supervisor/supervisord.conf;


exit 0;

