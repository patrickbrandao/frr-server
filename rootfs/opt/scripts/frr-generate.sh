#!/bin/bash

# Gerar arquivo daemons do FRR baseado na variavel env SERVICES e FIB_ENABLE: /data/frr/daemons
#========================================================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|frr-generate: $@"; echo "$now|frr-generate: $@" >> $initlogfile; };


    _log "Iniciando gerador de parametros do FRR";


    # Incluir config das variaveis de ambiente
    SYS_ENV="/opt/env.sh";
    _log "Incluindo variaveis de $SYS_ENV";
    [ -s "$SYS_ENV" ] && . $SYS_ENV;

    _log "Servicos iniciais: $SERVICES";
    _log "Opcoes: FIB_ENABLE=$FIB_ENABLE, FRR_TEMPLATE=$FRR_TEMPLATE, BGP_ASN=$BGP_ASN";

    # Salvar ambiente
    /opt/scripts/gen-report.sh "frr-generate";

    # Controle de servicos
    # - Ativos por padrao
    bgpd=yes;
    ospfd=yes;
    ospf6d=yes;
    pbrd=yes;
    bfdd=yes;


    # - Desativados por padrao
    ripd=no;
    ripngd=no;
    isisd=no;
    pimd=no;
    pim6d=no;
    ldpd=no;
    nhrpd=no;
    eigrpd=no;
    babeld=no;
    sharpd=no;
    fabricd=no;
    vrrpd=no;
    pathd=no;


    # Estatico
    vtysh_enable=yes;

    # Ativar SNMP
    mod_snmp="";
    [ "$SNMP_ENABLE" = "yes" ] && mod_snmp="-M snmp";

    # Opcoes de servicos
    # - com suporte SNMP
    zebra_options="  -A 127.0.0.1 $mod_snmp -s 90000000";
    bgpd_options="   -A 127.0.0.1 $mod_snmp"; # 
    ospfd_options="  -A 127.0.0.1 $mod_snmp";
    ospf6d_options=" -A ::1 $mod_snmp";
    ldpd_options="   -A 127.0.0.1 $mod_snmp";
    ripd_options="   -A 127.0.0.1 $mod_snmp";
    isisd_options="  -A 127.0.0.1 $mod_snmp";

    # - sem suporte SNMP
    ripngd_options=" -A ::1";
    pimd_options="   -A 127.0.0.1";
    pim6d_options="  -A ::1";
    nhrpd_options="  -A 127.0.0.1";
    eigrpd_options=" -A 127.0.0.1";
    babeld_options=" -A 127.0.0.1";
    sharpd_options=" -A 127.0.0.1";
    pbrd_options="   -A 127.0.0.1";
    staticd_options="-A 127.0.0.1";
    bfdd_options="   -A 127.0.0.1";
    fabricd_options="-A 127.0.0.1";
    vrrpd_options="  -A 127.0.0.1";
    pathd_options="  -A 127.0.0.1";

    # Opcoes gerais
    MAX_FDS=16384;
    #frr_global_options="";
    #watchfrr_options="";
    #frr_profile="";
    #frr_profile="traditional"
    #frr_profile="datacenter"
    # FRR_NO_ROOT="yes"
    # bgpd_wrap="/usr/bin/daemonize /usr/bin/mywrapper"
    #all_wrap=""

    # Ativar todos
    _services_enable_all(){
        bgpd=yes;     ospfd=yes;  ospf6d=yes;  pbrd=yes;    bfdd=yes;
        ripd=yes;     ripngd=yes; isisd=yes;   pimd=yes;    pim6d=yes;
        ldpd=yes;     nhrpd=yes;  eigrpd=yes;  babeld=yes;  sharpd=yes;
        fabricd=yes;  vrrpd=yes;  pathd=yes;
    };
    # Desativar todos
    _services_disable_all(){
        bgpd=no;      ospfd=no;   ospf6d=no;   pbrd=no;     bfdd=no;
        ripd=no;      ripngd=no;  isisd=no;    pimd=no;     pim6d=no;
        ldpd=no;      nhrpd=no;   eigrpd=no;   babeld=no;   sharpd=no;
        fabricd=no;   vrrpd=no;   pathd=no;
    };
    # Ativar defaults
    _services_enable_defaults(){
        _services_disable_all;
        bgpd=yes;     ospfd=yes;  ospf6d=yes; pbrd=yes;     bfdd=yes;
    };

    # Processar SERVICES
    service_words=$(echo "$SERVICES" | sed 's#,# #g');
    for word in $service_words; do

        # Ativar tudo
        [ "$word" = "all" ] && { _services_enable_all;  };

        # OSPF
        [ "$word" = "ospf" -o "$word" = "OSPF" ] && {
            _services_disable_all;
            ospfd=yes;  ospf6d=yes;  bfdd=yes;
        };

        # MESH
        [ "$word" = "mesh" -o "$word" = "MESH" ] && {
            _services_disable_all;
            bgpd=yes;     ospfd=yes;  ospf6d=yes;  pbrd=yes;    bfdd=yes;
            babeld=yes;   nhrpd=yes;  pimd=yes;    pim6d=yes;
        };

        # RIP
        [ "$word" = "rip" -o "$word" = "RIP" ] && {
            _services_disable_all;
            ripd=yes;    ripngd=yes;  bfdd=yes;
        };

        # RR - Router Reflector
        [ "$word" = "rr" -o "$word" = "RR" -o "$word" = "rs" -o "$word" = "RS" ] && {
            _services_disable_all;
            bgpd=yes;     ospfd=yes;  ospf6d=yes;  pbrd=yes;    bfdd=yes;
            FIB_ENABLE=no;
        };

        # LG - Looking Glass
        [ "$word" = "lg" -o "$word" = "LG" ] && {
            _services_disable_all;
            bgpd=yes;     ospfd=yes;  ospf6d=yes;  pbrd=yes;    bfdd=yes;
            FIB_ENABLE=no;
        };

        # PE (roteador backbone)
        [ "$word" = "pe" -o "$word" = "PE" ] && {
            _services_enable_defaults;
            # Adicionar LDP e Multicast
            ldpd=yes;
        };

        # Servicos unitarios, ativar
        [ "$word" = "bgpd"    ] && bgpd=yes;
        [ "$word" = "ospfd"   ] && ospfd=yes;
        [ "$word" = "ospf6d"  ] && ospf6d=yes;
        [ "$word" = "pbrd"    ] && pbrd=yes;
        [ "$word" = "bfdd"    ] && bfdd=yes;
        [ "$word" = "ripd"    ] && ripd=yes;
        [ "$word" = "ripngd"  ] && ripngd=yes;
        [ "$word" = "isisd"   ] && isisd=yes;
        [ "$word" = "pimd"    ] && pimd=yes;
        [ "$word" = "pim6d"   ] && pim6d=yes;
        [ "$word" = "ldpd"    ] && ldpd=yes;
        [ "$word" = "nhrpd"   ] && nhrpd=yes;
        [ "$word" = "eigrpd"  ] && eigrpd=yes;
        [ "$word" = "babeld"  ] && babeld=yes;
        [ "$word" = "sharpd"  ] && sharpd=yes;
        [ "$word" = "fabricd" ] && fabricd=yes;
        [ "$word" = "vrrpd"   ] && vrrpd=yes;
        [ "$word" = "pathd"   ] && pathd=yes;

    done;


    # Processar FIB_ENABLE
    if [ "$FIB_ENABLE" = "no" ]; then
        bgpd_options="   -A 127.0.0.1 --no_kernel";
    fi;


    # Gravar resultado
    mkdir -p /data/frr;

    # daemons
    (
        echo "bgpd=$bgpd";
        echo "ospfd=$ospfd";
        echo "ospf6d=$ospf6d";
        echo "ripd=$ripd";
        echo "ripngd=$ripngd";
        echo "isisd=$isisd";
        echo "pimd=$pimd";
        echo "pim6d=$pim6d";
        echo "ldpd=$ldpd";
        echo "nhrpd=$nhrpd";
        echo "eigrpd=$eigrpd";
        echo "babeld=$babeld";
        echo "sharpd=$sharpd";
        echo "pbrd=$pbrd";
        echo "bfdd=$bfdd";
        echo "fabricd=$fabricd";
        echo "vrrpd=$vrrpd";
        echo "pathd=$pathd";
        echo;
        echo "vtysh_enable=$vtysh_enable";
        echo;
        echo "zebra_options=\"$zebra_options\"";
        echo "mgmtd_options=\"$mgmtd_options\"";
        echo "bgpd_options=\"$bgpd_options\"";
        echo "ospfd_options=\"$ospfd_options\"";
        echo "ospf6d_options=\"$ospf6d_options\"";
        echo "ripd_options=\"$ripd_options\"";
        echo "ripngd_options=\"$ripngd_options\"";
        echo "isisd_options=\"$isisd_options\"";
        echo "pimd_options=\"$pimd_options\"";
        echo "pim6d_options=\"$pim6d_options\"";
        echo "ldpd_options=\"$ldpd_options\"";
        echo "nhrpd_options=\"$nhrpd_options\"";
        echo "eigrpd_options=\"$eigrpd_options\"";
        echo "babeld_options=\"$babeld_options\"";
        echo "sharpd_options=\"$sharpd_options\"";
        echo "pbrd_options=\"$pbrd_options\"";
        echo "staticd_options=\"$staticd_options\"";
        echo "bfdd_options=\"$bfdd_options\"";
        echo "fabricd_options=\"$fabricd_options\"";
        echo "vrrpd_options=\"$vrrpd_options\"";
        echo "pathd_options=\"$pathd_options\"";
        echo;
    ) > /data/frr/daemons;

    # Service list
    slist=$(cat /data/frr/daemons | egrep '=yes' | cut -f1 -d= | grep -v enable);
    SERVICE_LIST=$(echo $slist);
    echo "$SERVICE_LIST" > /data/frr/services;
    _log "Servicos selecionados: $SERVICES";



    # Templates
    # - Arquivo de destino
    FRRCONF="/data/frr/frr.conf";

    # - Variaveis do ambiente
    HNAME=$(hostname -f);


    # - Funcao para aplicar template com substituicoes
    _apply_template(){
        atconf="$1";
        _log "Aplicando variaveis no template $atconf para $FRRCONF";
        _log "HOSTNAME...: $HNAME";
        _log "ROUTERID...: $ROUTER_ID";
        _log "ROUTERID4..: $ROUTER_ID4";
        _log "ROUTERID6..: $ROUTER_ID6";
        _log "BGP_ASN....: $BGP_ASN";
        _log "SOURCE_IPV4: $SOURCE_IPV4";
        _log "SOURCE_IPV6: $SOURCE_IPV6";
        _log "LOGFILE....: $FRR_LOGFILE";
        cat $atconf | \
            sed "s#%HOSTNAME%#$HNAME#g" | \
            sed "s#%ROUTERID%#$ROUTER_ID#g" | \
            sed "s#%ROUTERID4%#$ROUTER_ID4#g" | \
            sed "s#%ROUTERID6%#$ROUTER_ID6#g" | \
            sed "s#%BGP_ASN%#$BGP_ASN#g" | \
            sed "s#%SOURCE_IPV4%#$SOURCE_IPV4#g" | \
            sed "s#%SOURCE_IPV6%#$SOURCE_IPV6#g" | \
            sed "s#%LOGFILE%#$FRR_LOGFILE#g" \
         > $FRRCONF;
        # Salvar copia inicial
        cat $FRRCONF > /data/frr/imported.conf;
    };


    # Template padrao
    if [ -s "$FRRCONF" ]; then
        _log "Arquivo $FRRCONF pressente, mantendo.";

    else
        _log "Arquivo$FRRCONF ausente. Analisando template $FRR_TEMPLATE";

        # Template usando script
        TSCRIPT="/opt/scripts/$FRR_TEMPLATE.sh";
        TCONFIG="/opt/shared/$FRR_TEMPLATE.conf";
        if [ -s "$TSCRIPT" ]; then
            # Usando script gerador

            # - arquivo conf de saida
            TMPCONF="/run/template-output.conf";

            # - rodar gerador
            _log "Gerando configuracao via script: $TSCRIPT > $TMPCONF";
            $TSCRIPT > $TMPCONF;

            # - importar conf gerada para config oficial
            _log "Importando template $TMPCONF";
            _apply_template "$TMPCONF";

        elif [ -s "$TCONFIG" ]; then

            # Usando config pronta
            _log "Usando template pronto: $TCONFIG";
            _apply_template "$TCONFIG";
            
        else
            # Template nao existe
            _log "Erro ao localizar template ($SRCCONF), gerar config limpa inicial";
            (
                echo '!';
                echo "frr version 10.3";
                echo "frr defaults traditional";
                echo "hostname $HNAME";
                echo "ip forwarding";
                echo "ipv6 forwarding";
                echo '!';
            ) > $FRRCONF;
        fi;
    fi;

    # Ajuste de permissao
    chown -R frr:frr /data/frr/daemons;
    chown -R frr:frr /data/frr/services;
    chown    frr:frr $FRRCONF;

    # Arquivo vtysh.conf
    VTYCONF="/data/frr/vtysh.conf";
    touch $VTYCONF;
    chown  frr:frr $VTYCONF;


exit 0;


