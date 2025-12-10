#!/bin/bash

# Instalar FRR
#========================================================================

    export DEBIAN_FRONTEND=noninteractive;
    apt-get install \
        -y --no-install-recommends \
        --assume-yes \
        -o Dpkg::Options::="--force-confold" \
        \
            frr \
            frr-doc \
            frr-pythontools \
            frr-rpki-rtrlib \
            frr-snmp \
            \
            || exit 13;


    # Padrao de servicos: todos ativos
    # - ativar protocolos fundamentais
    sed -i 's#ospfd=no#ospfd=yes#'      /etc/frr/daemons;
    sed -i 's#ospf6d=no#ospf6d=yes#'    /etc/frr/daemons;
    sed -i 's#bfdd=no#bfdd=yes#'        /etc/frr/daemons;
    sed -i 's#pbrd=no#pbrd=yes#'        /etc/frr/daemons;
    sed -i 's#bgpd=no#bgpd=yes#'        /etc/frr/daemons;
    sed -i 's#ldpd=no#ldpd=yes#'        /etc/frr/daemons;

    # - ativar incomuns
    sed -i 's#ripd=no#ripd=yes#'        /etc/frr/daemons;
    sed -i 's#ripngd=no#ripngd=yes#'    /etc/frr/daemons;
    sed -i 's#isisd=no#isisd=yes#'      /etc/frr/daemons;
    sed -i 's#pimd=no#pimd=yes#'        /etc/frr/daemons;
    sed -i 's#pim6d=no#pim6d=yes#'      /etc/frr/daemons;
    sed -i 's#nhrpd=no#nhrpd=yes#'      /etc/frr/daemons;
    sed -i 's#eigrpd=no#eigrpd=yes#'    /etc/frr/daemons;
    sed -i 's#babeld=no#babeld=yes#'    /etc/frr/daemons;
    sed -i 's#sharpd=no#sharpd=yes#'    /etc/frr/daemons;
    sed -i 's#fabricd=no#fabricd=yes#'  /etc/frr/daemons;
    sed -i 's#vrrpd=no#vrrpd=yes#'      /etc/frr/daemons;
    sed -i 's#pathd=no#pathd=yes#'      /etc/frr/daemons;


    # Templates
    mkdir -p /usr/share/frr;
    cat /usr/share/frr/daemons | \
        egrep -v '^#' | \
        egrep -v '^$' > /etc/frr/daemons /usr/share/frr/daemons;


    # Transformar /etc/frr em link simbolico para pasta
    # do volume
    mkdir /data/frr;
    rm -rf /etc/frr 2>/dev/null;
    ln -sf /data/frr /etc/frr;

    # Historico no volume
    rm -rf /root/.history_frr;
    ln -sf /data/frr/.history_frr  /root/.history_frr;

    # Ambiente basico
    mkdir -p /var/run/frr;
    chown frr:frr /var/run/frr -R;


    # Comando show nativo no shell
    (
        echo '#!/bin/sh';
        echo "echo";
        echo "eval \"vtysh -c 'show \$@'\"";
        echo "echo";
    ) > /usr/bin/show;
    chmod +x /usr/bin/show;



exit 0;


