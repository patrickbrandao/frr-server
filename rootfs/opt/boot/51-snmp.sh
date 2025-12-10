#!/bin/bash

# SNMP Server
#========================================================================

    initlogfile="/var/log/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|snmp: $@"; echo "$now|snmp: $@" >> $initlogfile; };

    # Variaveis
    HS=$(hostname -s);
    HF=$(hostname -f);

    # Configuracao do servidor SNMP
    _log "Iniciando configuracao padrao de servidor SNMP: /run/snmp/snmpd.conf";
    mkdir -p /run/snmp;
    (
        echo;
        echo "rocommunity \"$SNMP_COMMUNITY\"";
        echo "rocommunity6 \"$SNMP_COMMUNITY\"";
        echo;
        echo "SysContact \"$SNMP_CONTACT\"";
        echo "SysLocation \"$SNMP_LOCATION\"";
        echo "SysDescr \"$SNMP_DESCRIPTION\"";
        echo "sysName \"$(hostname)\"";
        echo;
        echo "agentaddress unix:/run/snmp/snmpd.socket,udp:$SNMP_PORT,udp6:$SNMP_PORT,tcp6:$SNMP_PORT,tcp:$SNMP_PORT";
        echo;
        echo "com2sec notConfigUser  default  $SNMP_COMMUNITY";
        echo;
        echo "group notConfigGroup v1 notConfigUser";
        echo "group notConfigGroup v2c notConfigUser";
        echo;
        echo "view    systemview    included    .1";
        echo;
        # incluir tabela de rotas?
        if [ "$SNMP_VIEW_ROUTES" = "yes" ]; then
            echo "# SNMP_VIEW_ROUTES ativo, liberando acesso completo";
            echo;
        else
            echo "# SNMP_VIEW_ROUTES desativado, restringindo acesso a rotas";
            echo;
            echo "# Remove ipRouteTable from view";
            echo "view all    excluded  .1.3.6.1.2.1.4.21";
            echo;
            echo "# Remove ipNetToMediaTable from view";
            echo "view all    excluded  .1.3.6.1.2.1.4.22";
            echo;
            echo "# Remove ipNetToPhysicalPhysAddress from view";
            echo "view all    excluded  .1.3.6.1.2.1.4.35";
            echo;
            echo "# Remove ipCidrRouteTable  from view";
            echo "view all    excluded  .1.3.6.1.2.1.4.24";
            echo;
            echo "# Optionally allow SNMP public info (sysName, location, etc)";
            echo "view system included  .iso.org.dod.internet.mgmt.mib-2.system";
            echo;
        fi
        echo;
        echo "master agentx";
        echo "agentXSocket tcp:localhost:705,/run/agentx/master";
        echo "agentXPerms 0660 0550 nobody frr";
        echo;
    ) > /run/snmp/snmpd.conf

    # Link simbolico no caminho antigo
    ln -sf /run/snmp/snmpd.socket /run/snmpd.socket;

    # Diretorio do agentx
    mkdir -p /run/agentx;
    chmod 0550 /run/agentx;


exit 0;

