#!/bin/bash

# Instalar pacotes do Debian
#========================================================================

    # Atualizar debian
    apt-get -y update       || exit 11;
    apt-get -y upgrade      || exit 12;
    apt-get -y dist-upgrade || exit 13;

    # Pacote da base
    export DEBIAN_FRONTEND=noninteractive;
    apt-get install \
        -y --no-install-recommends \
        --assume-yes \
        -o Dpkg::Options::="--force-confold" \
        \
            bash procps gawk sed grep mawk openssl psutils \
            tzdata curl wget ca-certificates iproute2 \
            python3 python3-pip supervisor htop psmisc coreutils \
            uuid uuid-runtime util-linux strace \
            \
            cron locales logrotate zstd xz-utils zip \
            tcpdump mtr-tiny traceroute \
            iputils-arping iputils-ping iputils-tracepath \
            fping whois \
            net-tools dnsutils \
            \
            snmp snmpd \
            \
            binutils binutils-common \
            bsdutils debianutils diffutils patch \
            file findutils hostname \
            adduser sudo \
            bzip2 tar gzip unzip zstd xz-utils \
            \
            nftables \
            \
            rsyslog rsyslog-gnutls rsyslog-openssl \
            \
            mc \
            \
            || exit 11;

exit 0;
