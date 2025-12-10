#!/bin/bash

# Pasta para guardar backups:
mkdir -p /run/report;

# Nome do relatorio
REPORT_NAME="$1";
[ "x$REPORT_NAME" = "x" ] && REPORT_NAME="default";

# Data e hora
DTIME=$(date '+%Y-%m-%d-%H%M');

# Extrair informacoes do sistema caso seja
# necessario analisar o backup (casos de caos!)
_exec_and_md(){
    echo "## $1";          # titulo
    echo "Comando: $1";    # comando
    echo '```stdout';      # abrir bloco de informacao
    eval "$1" 2>/dev/null; # rodar comando
    echo '```';            # fechar bloco de informacao
    echo;
};

# Criar arquivo MD com relatorio do sistema:
(
    echo '# Linux - Report';
    echo;
    # network
    _exec_and_md 'ip -4 addr show';
    _exec_and_md 'ip -6 addr show';
    _exec_and_md 'ip -4 route show';
    _exec_and_md 'ip -6 route show';
    _exec_and_md 'nft list ruleset';
    echo;
    # env
    _exec_and_md 'env';
    _exec_and_md 'set';
    echo;
    # config linux
    _exec_and_md 'hostname';
    _exec_and_md 'hostname -f';
    _exec_and_md 'cat /etc/hostname';
    _exec_and_md 'cat /etc/hosts';
    _exec_and_md 'cat /etc/os-release';
    _exec_and_md 'cat /etc/machine-id';
    _exec_and_md 'cat /etc/passwd';
    echo;
    # process
    _exec_and_md 'ps aux';
    _exec_and_md 'cat /proc/cpuinfo';
    _exec_and_md 'cat /proc/meminfo';
    _exec_and_md 'cat /proc/mounts';
    _exec_and_md 'lsmod';
    echo;
    # filesystem
    _exec_and_md 'fdisk -l';
    _exec_and_md 'df';
    _exec_and_md 'df -h';
    _exec_and_md 'lsblk';
    _exec_and_md 'lsblk --output-all -J';
    echo;
    # hardware
    _exec_and_md 'lscpu';
    _exec_and_md 'lspci';
    _exec_and_md 'lsirq';
    _exec_and_md 'lstopo';
    _exec_and_md 'lspci -vvv';
    echo;
) > /run/REPORT-$DTIME-$REPORT_NAME.md;


