#!/bin/bash

# Idioma padrao
#========================================================================

    [ "x$LANG" = "x" ] && LANG="en_US.UTF-8";
    locale-gen $LANG;


exit 0;
