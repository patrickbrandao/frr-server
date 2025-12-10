#!/bin/bash

    # Incluir config das variaveis de ambiente
    SYS_ENV="/opt/env.sh";
    [ -s "$SYS_ENV" ] && . $SYS_ENV;

	mkdir -p /run/snmp;
	exec /usr/sbin/snmpd -f -Lsd -Lo -u Debian-snmp -g Debian-snmp -I -smux -p /run/snmp/snmpd.pid;

exit 0;
