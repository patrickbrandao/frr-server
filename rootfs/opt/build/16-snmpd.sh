#!/bin/bash

# Ajustes no SNMP Server
#========================================================================

    # Apagar config SNMP Client
    echo -n > /etc/snmp/snmp.conf;

    # Link simbolico do snmpd para pasta em /run
    mv /etc/snmp/snmpd.conf  /etc/snmp/orig-snmpd.conf;
    ln -sf /run/snmp/snmpd.conf /etc/snmp/snmpd.conf;


exit 0;

