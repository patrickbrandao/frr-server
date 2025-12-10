#!/bin/bash

# Limpar ambiente e deixar container minimalista
#========================================================================

    echo "# Retirar arquivos dispensaveis";

    # rotinas agendas de sistemas nao utilizados
    (
        rm -f /etc/cron.daily/apt;
        rm -f /etc/cron.daily/apt-compat;
        rm -f /etc/cron.daily/dpkg;
        rm -f /etc/cron.daily/wtmp;
        rm -f /etc/cron.daily/btmp;
        rm -f /etc/cron.daily/apache2;
        rm -f /etc/cron.daily/rsyslog;
        rm -f /etc/cron.daily/alternatives;
    ) 2>/dev/null;

    # rotacionador de logs nao utiliados
    (
        rm -f /etc/logrotate.d/dpkg;
        rm -f /etc/logrotate.d/alternatives;
        rm -f /etc/logrotate.d/apt;
        rm -f /etc/logrotate.d/wtmp;
        rm -f /etc/logrotate.d/rsyslog;
        rm -f /etc/logrotate.d/btmp;
        rm -f /etc/logrotate.d/frr; # resumido no 13-logrotate
    ) 2>/dev/null;

    # arquivos temporarios
    rm -rf /tmp/*       2>/dev/null;
    rm -rf /var/tmp/*   2>/dev/null;

    # limpeza do debian
    # - seguro
    rm -rf "/var/cache/apt"       2>/dev/null;
    rm -rf "/var/cache/debconf"   2>/dev/null;

    rm -rf "/var/lib/dpkg"        2>/dev/null;
    rm -rf "/var/lib/apt"         2>/dev/null;
    rm -rf "/var/lib/systemd"     2>/dev/null;
    rm -rf "/var/lib/apache2"     2>/dev/null;

    rm -rf "/var/log/apache2"     2>/dev/null;
    rm -rf "/var/log/apt"         2>/dev/null;
    rm -rf "/var/log/journal"     2>/dev/null;
    rm -rf "/var/log/supervisor"  2>/dev/null;

    rm -rf "/usr/share/man"       2>/dev/null;
    rm -rf "/usr/share/doc"       2>/dev/null;
    rm -rf "/usr/share/info"      2>/dev/null;

    rm -rf "/usr/share/common-licenses" 2>/dev/null;
    rm -f "/var/log/alternatives.log"   2>/dev/null;
    rm -f "/var/log/dpkg.log"           2>/dev/null;
    rm -f "/var/log/fontconfig.log"     2>/dev/null;
    rm -f "/var/log/lastlog"            2>/dev/null;
    rm -f "/var/log/README"             2>/dev/null;

exit 0;

