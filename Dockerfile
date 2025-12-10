#================================================================================
#
# Container Debian + FRR
#
# * Todos os dados gerados pelo container serao armazenados em /data
#   Monte sua pasta ou volume no /data para ter os dados persistentes e backups.
#
# Variaveis de ambiente:
#
# Firewall
#    FIREWALL_ENABLE = yes|no (no), controla o firewall (ativar/desativar)
#    FIREWALL_PERMIT_PRIVATES = yes|no (yes), permite todos os prefixos privados
#    FIREWALL_PERMIT_NETWORKS = redes autorizadas, separar por virgula
#
# Contador de conexoes
#    COUNTERS_ENABLE = yes|no (yes), controle do contador (ativar/desativar)
#    
# Log externo
#    LOGSERVER_ENABLE = yes|no (no), ativa log externo
#    LOGSERVER_HOST = ip do servidor de logs (syslog server)
#    LOGSERVER_PORT = porta do servidor syslog
#
# Alteracoes na rede do container
#    INTERFACE = interface padrao para manipular, padrao: eth0
#    VLANS = manifesto de vlans a criar, separar por pipe "|",
#            registros com valores separados por virgula: VID,IPV4,IPV6
#    LAN_RESET = yes|no (no), apagar config da interface em $INTERFACE
#    GATEWAY_RESET = yes|no (no), apagar gateway padrao original do container
#    SUPERGW_ENABLE = criar SuperGateway (/1) apontando para o gateway do container
#
# Controle do FRR
#    FIB_ENABLE = yes|no (yes), ativar FIB (adicionar rotas do kernel) do BGP
#    FRR_LOGFILE = arquivo de logs, padrao /data/logs/frr.log
#    SERVICES = servicos a ativar durante o boot, separar por virgula
#
#    Nomes explicitos dos servicos:
#        bgpd
#        ospfd
#        ospf6d
#        ripd
#        ripngd
#        isisd
#        pimd
#        pim6d
#        ldpd
#        nhrpd
#        eigrpd
#        babeld
#        sharpd
#        pbrd
#        bfdd
#        fabricd
#        vrrpd
#        pathd
#
#    Servicos ativos por padrao (valor padrao de SERVICES)
#        ospf, ospfd, ospf6d, bfdd, bgpd, pbrd
#    
#    Palavras chaves para resumir
#        all  = rodar todos os servicos
#        ospf = rodar OSPFv2 (ospfd) e OSPFv3 (ospf6d) e BFD (bfdd)
#        rip  = rodar RIPv2 (ripd) e RIPv3 (ripngd) e BFD (bfdd)
#        rr   = rodar apenas BGP (bgpd) e OSPF, sem FIB (FIB_ENABLE=no)
#        rs   = rodar apenas BGP (bgpd) e OSPF, sem FIB (FIB_ENABLE=no)
#        pe   = rodar servicos PE: OSPF, BGP, LDP, BFD, PIM (pimd e pim6d)
#        lg   = rodar BGP apenas, sem FIB (FIB_ENABLE=no)
#        mesh = rodar OSPF, BGP e BABEL
#
# Controle de template (funciona somente no primeiro boot)
#    FRR_TEMPLATE = nome do template inicial do container (config de boot), opcoes:
#        router-mesh
#        router-pe
#        router-pe-legacy
#        router-rr-lab01
#    BGP_ASN = ASN padrao da config BGP, padrao 64900
#    IGP_NETMODE = broadcast|point-to-point (broadcast), modo de rede padrao das interfaces OSPF
#    IGP_ALL_DEVS = yes|no (yes), ativar IGP em todas as interfaces? quando "no" ativa somente em vlans
#
#    ROUTER_ID = router-id (32bits no formato ipv4), padrao: primeiro ip de loopback ou primeiro IP local
#    SOURCE_IPV4 = ip de origem IPv4, padrao: primeiro IPv4 de loopback ou primeiro IP local
#    SOURCE_IPV6 = ip de origem IPv6, padrao: primeiro IPv6 de loopback ou primeiro IP local
#
# Configuracao de SNMP
#    SNMP_ENABLE = yes|no (yes), ativar servidor SNMP
#    SNMP_VIEW_ROUTES = yes|no (no), ativar dump da tabela de rotas via SNMP
#    SNMP_COMMUNITY = community de acesso SNMP, padrao: frr-server
#    SNMP_LOCATION = localizacao GPS numerica ou endereco do POP
#    SNMP_CONTACT = nome do administrador
#    SNMP_DESCRIPTION = descricao da funcao do container
#    SNMP_PORT = porta SNMP, padrao 161
#
#================================================================================

# Debian 13
FROM debian:trixie

# Variaveis globais de ambiente
ENV \
    MAINTAINER="Patrick Brandao <patrickbrandao@gmail.com>" \
    TERM=xterm \
    SHELL=/bin/bash \
    TZ=America/Sao_Paulo \
    PS1='\u@\h:\w\$ ' \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# Copiar arquivos personalizados:
ADD rootfs  /

# Preparar o debian com todos os pacotes
RUN ( \
    cd /opt/build || exit 1; \

    /bin/sh /opt/build/01-debian-packages.sh || exit $?; \
    /bin/sh /opt/build/02-debian-changes.sh  || exit $?; \
    /bin/sh /opt/build/03-debian-frr.sh      || exit $?; \
    /bin/sh /opt/build/11-crontab.sh         || exit $?; \
    /bin/sh /opt/build/12-supervisor.sh      || exit $?; \
    /bin/sh /opt/build/13-logrotate.sh       || exit $?; \
    /bin/sh /opt/build/14-opt-exec.sh        || exit $?; \
    /bin/sh /opt/build/15-nftables.sh        || exit $?; \
    /bin/sh /opt/build/16-snmpd.sh           || exit $?; \
    /bin/sh /opt/build/18-ram-ops.sh         || exit $?; \
    /bin/sh /opt/build/19-cleanup.sh         || exit $?; \
    \
)

LABEL org.opencontainers.image.title="FreeRangeRouting" \
    org.opencontainers.image.description="FRR Server" \
    org.opencontainers.image.source="https://frrouting.org/" \
    org.opencontainers.image.url="https://oci.tmsoft.com.br" \
    org.opencontainers.image.maintainer="patrickbrandao@gmail.com" \
    org.opencontainers.image.version=1.0.0


# Portas
# BGP...: 179/tcp
# LDP...: 646/tcp
# RIP...: 520/udp
# RIPng.: 521/udp
# LDP...: 646/udp
# BFD...: 3784/udp
# BFD...: 4784/udp
# Babel.: 6696/udp
EXPOSE 179/tcp 646/tcp 520/udp 521/udp 646/udp 3784/udp 4784/udp 6696/udp

# Script de inicializacao (pos-preparativos -> supervisord)
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["/usr/bin/supervisord","--nodaemon","-c","/etc/supervisor/supervisord.conf"]


