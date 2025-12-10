#!/bin/bash

# Crontab
#========================================================================

    # Criar diretorios dos scripts periodicos:
    # - intervalos curtos
    mkdir -p /etc/cron.1min;
    mkdir -p /etc/cron.5min;
    mkdir -p /etc/cron.10min;
    mkdir -p /etc/cron.15min;
    mkdir -p /etc/cron.30min;
    # - intervalos basicos
    mkdir -p /etc/cron.hourly;
    mkdir -p /etc/cron.daily;
    mkdir -p /etc/cron.weekly;
    mkdir -p /etc/cron.monthly;
    # - agendadores de dias da semana
    mkdir -p /etc/cron.monday;
    mkdir -p /etc/cron.tuesday;
    mkdir -p /etc/cron.wednesday;
    mkdir -p /etc/cron.thursday;
    mkdir -p /etc/cron.friday;
    mkdir -p /etc/cron.saturday;
    mkdir -p /etc/cron.sunday;

    # Criar config de contrab
    (
        echo;
        echo "SHELL=/bin/sh";
        echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
        echo;
        echo '# Example of job definition:';
        echo '# .---------------- minute (0 - 59)';
        echo '# |  .------------- hour (0 - 23)';
        echo '# |  |  .---------- day of month (1 - 31)';
        echo '# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...';
        echo '# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat';
        echo '# |  |  |  |  |';
        echo '# *  *  *  *  * user-name command to be executed';
        echo;
        echo;
        echo "0  *  *  *  *  root run-parts --regex '.*' /etc/cron.hourly";
        echo "0  2  *  *  *  root run-parts --regex '.*' /etc/cron.daily";
        echo "0  3  *  *  6  root run-parts --regex '.*' /etc/cron.weekly";
        echo "0  5  1  *  *  root run-parts --regex '.*' /etc/cron.monthly";
        echo;
        for min in 1 5 10 15 30; do
        echo "*/$min  *  *  *  *  root run-parts --regex '.*' /etc/cron.${min}min";
        done;
        echo;
        echo "0  0  *  *  0  root run-parts --regex '.*' /etc/cron.sunday";
        echo "0  0  *  *  1  root run-parts --regex '.*' /etc/cron.monday";
        echo "0  0  *  *  2  root run-parts --regex '.*' /etc/cron.tuesday";
        echo "0  0  *  *  3  root run-parts --regex '.*' /etc/cron.wednesday";
        echo "0  0  *  *  4  root run-parts --regex '.*' /etc/cron.thursday";
        echo "0  0  *  *  5  root run-parts --regex '.*' /etc/cron.friday";
        echo "0  0  *  *  6  root run-parts --regex '.*' /etc/cron.saturday";
        echo;
    ) > /etc/crontab;

    # Ajustar caminho do run-parts
    # em bin
    [ -f /usr/bin/run-parts -a ! -e /usr/sbin/run-parts ] && {
        echo "# run-parts em /usr/bin";
        ln -sf /usr/bin/run-parts /usr/sbin/run-parts;
    };
    # em sbin
    [ -f /usr/sbin/run-parts -a ! -e /usr/bin/run-parts ] && {
        echo "# run-parts em /usr/sbin";
        ln -sf /usr/sbin/run-parts /usr/bin/run-parts;        
    };



exit 0;


