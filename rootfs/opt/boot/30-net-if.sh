#!/bin/bash

# Interfaces de rede vlan adicionais
#========================================================================

    initlogfile="/var/log/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|net-if: $@"; echo "$now|net-if: $@" >> $initlogfile; };
    _eval(){ _log "Running: $@"; out=$(eval "$@" 2>&1); sn="$?"; _log "Output [$@] = stdno[$sn] stdout[$out]"; };
    _vlan_create(){
        tdev="$1";
        xvid="$2";
        xmac="$3";
        xdev="$tdev.$xvid";

        _log "vlan-create $tdev vid $xvid name $xdev mac=$xmac";

        # Criar interface vlan (tentar 3x)
        ip link add link $tdev name $xdev type vlan id $xvid || \
            ip link add link $tdev name $xdev type vlan id $xvid || \
                ip link add link $tdev name $xdev type vlan id $xvid;

        # Alterar MAC
        [ "x$xmac" = "x" -o "$xmac" = "none" ] || \
            ip link set $xdev address $xmac || \
                ip link set $xdev address $xmac;

        # Ativar interface
        ip link set up dev $xdev || \
            ip link set up dev $xdev;

    };


    # Manifesto de VLANs
    # - Separar manifestos por virgula
    # - Cada registro separado por PIPE "|", cada registro contendo os campos:
    #   > VID..: numero da vlan
    #   > IPV4.: endereco IPv4 fixo
    #   > IPV6.: endereco IPv6 fixo
    #   > GW4..: gateway IPv4 por essa rede, opcional
    #   > GW6..: gateway IPv6 por essa rede, opcional
    #   > MAC..: mac address da interface vlan, opcional
    #
    VLANS=$(echo $VLANS | sed 's#|# #g');
    VLANS=$(echo $VLANS);


    # Sem VLANS definidas
    [ "x$VLANS" = "x" ] && {
        _log "Sem manifesto de VLANs presentes";
        exit 0;
    };


    # Interface mestre precisa existir
    DNET="/sys/class/net/$INTERFACE";
    [ -e "$DNET/carrier" ] || {
        _log "Interface principal nao existe ($INTERFACE)";
        exit 0;
    };


    # Salvar gateway antes de mexer na rede

    # Detectar gateway padrao IPv4
    GATEWAY_IPV4_ADDR=$(ip -o -4 ro get 1.2.3.4 | sed 's#via.#|#g'| cut -f2 -d'|' | awk '{print $1}');
    if [ "x$GATEWAY_IPV4_ADDR" = "x" ]; then
        _log "Gateway IPv4 nao detectado, ignorando salvamento";
    else
        _log "Gateway IPv4 inicial: $GATEWAY_IPV4_ADDR";
        GATEWAY_IPV4_FOUND=yes;
        echo "$GATEWAY_IPV4_ADDR" > /run/gateway-ipv4;
    fi;


    # Detectar gateway padrao IPv6
    GATEWAY_IPV6_ADDR=$(ip -o -6 ro get 2001::1 | sed 's#via.#|#g'| cut -f2 -d'|' | awk '{print $1}');
    if [ "x$GATEWAY_IPV6_ADDR" = "x" ]; then
        _log "Gateway IPv6 nao detectado, ignorando salvamento";
    else
        _log "Gateway IPv6 inicial: $GATEWAY_IPV6_ADDR";
        echo "$GATEWAY_IPV6_ADDR" > /run/gateway-ipv6;
    fi;


    # Deletar gateway padrao
    if [ "$GATEWAY_RESET" = "yes" ]; then    
        _log "Gateway Reset: Apagando gateway padrao";
        for i in 1 2; do
            ip -4 route del default;
            ip -6 route del default;
        done 2>/dev/null;
    else
        _log "Gateway Reset desativado";
    fi;


    # Apagar IPs da interface
    if [ "$LAN_RESET" = "yes" ]; then
        _log "Lan Reset: Apagando IPs nativos";
        # - Apagar IPv4
        ip -4 addr show dev $INTERFACE | grep "inet"| awk '{print $2}' | while read x; do ip -4 addr del $x dev $INTERFACE; done;
        # - Apagar IPv6 (preservar link-local)
        ip -6 addr show dev $INTERFACE | grep "inet6" | grep -v fe80 | awk '{print $2}' | while read x; do ip -6 addr del $x dev $INTERFACE; done;
    else
        _log "Lan Reset desativado";
    fi;


    # Criar Vlans e definir IPs
    ruleid=10;
    metric4=240; metric6=240;
    for vreg in $VLANS; do
        evid=$(echo  $vreg  | cut -f1 -d",");
        vip4=$(echo  $vreg  | cut -f2 -d",");
        vip6=$(echo  $vreg  | cut -f3 -d",");
        vgwt4=$(echo $vreg  | cut -f4 -d",");
        vgwt6=$(echo $vreg  | cut -f5 -d",");
        vmac=$(echo  $vreg  | cut -f6 -d",");

        # separar interface de vlan-id
        vdev="$INTERFACE.$evid";

        _log "VLAN Def, vdev=$vdev [dev=$INTERFACE evid=$evid] vip4=$vip4 vip6=$vip6 vmac=$vmac vgwt4=$vgwt4 vgwt6=$vgwt6 vtbl=$vtbl";

        # Criar interface vlan
        _vlan_create "$INTERFACE" "$evid" "$vmac";

        # Atribuir IPv4
        [ "x$vip4" = "x" -o "$vip4" = "none" ] || {
            # atribuir endereco na interface
            _eval "ip -4 addr add "$vip4" dev $vdev";
        };

        # Atribuir IPv6
        [ "x$vip6" = "x" -o "$vip6" = "none" ] || {
            _eval "ip -6 addr add "$vip6" dev $vdev";
        };

        # Rota padrao ipv4
        if [ "x$vgwt4" = "x" -o "$vgwt4" = "none" ]; then
            _log "VLAN $vdev sem gateway IPv4";
        else
            _log "Gateway IPv4 via VLAN $vdev: $vgwt4";
            _eval "ip -4 route add default via $vgwt4 metric $metric4 proto static";
            metric4=$(($metric4+1));
        fi;

        # Rota padrao ipv6
        if [ "x$vgwt6" = "x" -o "$vgwt6" = "none" ]; then
            _log "VLAN $vdev sem gateway IPv6";
        else
            _log "Gateway IPv4 via VLAN $vdev: $vgwt4";
            _eval "ip -6 route add default via $vgwt6 metric $metric6 proto static";
            metric6=$(($metric6+1));
        fi; 
    done;


exit 0;


