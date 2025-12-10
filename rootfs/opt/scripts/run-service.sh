#!/bin/bash

# Script para execucao generica de servicos
#========================================================================================================

# Argumentos:
# 1. Arquivo com variaveis de ambiente, padrao /opt/env.sh
# 2. Programa a ser exececutado, padrao na variavel SERVICE_SCRIPT

    SENV="$1"; # arquivo de variaveis de ambiente
    DSVC="$2"; # programa principal

# 1 - Variaveis de ambiente
    # Padrao: /opt/env.sh
    [ "x$SENV" = "x" -o "$SENV" = "default" ] && SENV="/opt/env.sh";
    # Env principal - Incluir apenas se existir
    [ -f "$SENV" ] && . "$SENV";

# 2 - Variaveis de ambiente geral do container
    SERVICE="$SERVICE_SCRIPT";
    [ "x$SERVICE" = "x" ] && SERVICE="$DSVC";
    [ "x$SERVICE" = "x" ] && SERVICE="sleep 5";

# Rodar substituindo processo
    eval "exec $SERVICE";

# Fallback caso o eval exec falhe.
    sleep 5;
