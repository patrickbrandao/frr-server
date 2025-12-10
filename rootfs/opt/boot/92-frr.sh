#!/bin/bash

# Adicionar super gateway para nao requerer rotas igp
#========================================================================

    initlogfile="/data/logs/init.log";
    _log(){ now=$(date "+%Y-%m-%d-%T"); echo "$now|frr-boot: $@"; echo "$now|frr-boot: $@" >> $initlogfile; };

    ztouch(){
        touch  "$1";
        chown frr:frr "$1";
        chmod 0644    "$1";
    };
    zmkdir(){
        mkdir -p "$1";
        chown -R frr:frr "$1";
        chmod 0700    "$1";
    };


    # Pasta do FRR no volume container
    # Garantir pasta do volume
    zmkdir /data/frr;

    # Historico do vtysh
    ztouch /data/frr/.history_frr;

    # Conferir todas as configs no volume
    if [ -d /etc/frr -a -L /etc/frr ]; then
        # /etc/frr link ok
        _log "Diretorio /etc/frr ok (link para /data/frr)";
    else
        # /etc/frr nao esta em conformidade
        cd /etc/frr && {
            _log "Analisando diretorio /etc/frr";
            # sincronizar arquivos novos com o volume
            for item in *; do
                [ -e /data/frr/$item ] || cp -rav $item /data/frr/;
            done;
        };
        # retirar /etc/frr e jogar no volume
        _log "Movendo operacao de /etc/frr para /data/frr";
        rm -rf /etc/frr;
        ln -sf /data/frr /etc/frr;
        zmkdir /data/frr;
    fi;

    # Pasta de execucao
    zmkdir /run/frr;


    # Criando opcoes de servicos
    if [ -s /data/frr/daemons -a -s /data/frr/services -a /data/frr/frr.conf ]; then
        # Opcoes de servico ja foram configuradas
        # na primeira execucao,
        # nao vamos mudar.
        # O administrador deve apagar o arquivo daemons
        # se desejar reprogramar a funcao do container
        _log "Opcoes de servico herdadas da primeira execucao em /data/frr/daemons";

    else
        # Requer construcao das opcoes de servico
        _log "Requer configurando de servicos FRR";
        /opt/scripts/frr-generate.sh;
    fi;



exit 0;



