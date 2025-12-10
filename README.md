
# Container FRR Server

Container para rodar FRR em qualquer topologia (RR, RS, Router, Looking Glass, ...)
Suporte a envio de logs para upstream syslog server.


## Construir container

```bash

sh build.sh

```


## Container de desenvolvimento do zero

```bash

docker rm -f frr-server-dev;
docker run -d --name frr-server-dev -h frr-server-dev --network network_public debian:trixie sleep 999111;
docker exec -it --user root frr-server-dev bash;

```
## Variáveis de ambiente

```
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
```

## Ambiente de teste

### Rede

Rode os scripts em ./tests/


### Teste de informacoes SNMP (dentro do container)


```

. /opt/env.sh;

# Informações Gerais
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT system;

# Informações BGP gerais
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT 1.3.6.1.2.1.15;

# Peers BGP
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT 1.3.6.1.2.1.15.3;

# Rotas OSPF
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT 1.3.6.1.2.1.14;

# OSPF RouterID
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT .1.3.6.1.2.1.14.1.1;

# Zebra/Routing MIB (FRR específico)
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT .1.3.6.1.4.1.3317;


# Private/Secret values
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT .1.3.6.1.6.3.15;
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT .1.3.6.1.6.3.16;
snmpwalk -v2c -c "$SNMP_COMMUNITY" localhost:$SNMP_PORT .1.3.6.1.6.3.18;



```


## Comandos mais comuns no FRR

```

# Analise de BGP

    show ip bgp summary
    show bgp summary

    show bgp ipv4
    show bgp ipv6

    show bgp ipv4 summary
    show bgp ipv6 summary

    show bgp ipv4 unicast summary
    show bgp ipv6 unicast summary

    # Analise de peering BGP:
    show bgp ipv4 neighbors 10.7.7.1
    show bgp ipv4 neighbors 10.7.7.1 flap-statistics
    show bgp ipv4 neighbors 10.7.7.1 prefix-counts
    show bgp ipv4 neighbors 10.7.7.1 advertised-routes
    show bgp ipv4 neighbors 10.7.7.1 received-routes
    show bgp ipv4 neighbors 10.7.7.1 routes

    show bgp neighbors 10.120.0.1
    show bgp neighbors 2001:db8:10:120::1

    # Reset/refresh de peering BGP:
    clear bgp 10.7.7.1
    clear bgp 10.7.7.1 in
    clear bgp 10.7.7.1 out
    clear bgp 10.7.7.1 soft
    clear bgp 10.7.7.1 soft in
    clear bgp 10.7.7.1 soft out

    # Reset/refresh geral de peerings BGP:
    clear bgp *


    # Analise de OSPFv2
    show ip ospf
    show ip ospf neighbors
    show ip ospf neighbor eth0
    show ip ospf neighbor eth0 detail
    show ip ospf neighbor detail
    show ip ospf neighbor detail all
    show ip ospf neighbor detail all json
    show ip ospf database
    show ip ospf interface
    show ip ospf interface json
    show ip ospf interface traffic
    show ip ospf interface traffic eth0
    show ip ospf interface traffic eth0 json
    show ip ospf mpls-te interface
    show ip ospf mpls-te router
    show ip ospf route
    show ip ospf vrf

    # Analise de OSPFv3
    show ipv6 ospf6
    show ipv6 ospf6 neighbor
    show ipv6 ospf6 neighbor detail
    show ipv6 ospf6 database
    show ipv6 ospf6 interface
    show ipv6 ospf6 interface  traffic
    show ipv6 ospf6 interface  traffic eth0
    show ipv6 ospf6 route

    # Analise de BGP-EBPN:
    show bgp ipv4 unicast summary
    show bgp l2vpn evpn summary
    show bgp l2vpn evpn
    show evpn
    show evpn vni detail
    show evpn vni 100
    show evpn mac vni 100


```



