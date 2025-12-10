#!/bin/bash

# Tornar scripts do projeto executaveis
#========================================================================

    echo "# Ajustes de scripts executaveis em /opt";
    chmod +x /opt/*;
    chmod +x /opt/scripts/*;
    chmod +x /opt/boot/*;
    chmod +x /opt/build/*;

    # Script de crontab
    chmod +x /etc/cron.*/*;

exit 0;
