#!/bin/sh
set -e

# Démarrer Xvfb
export DISPLAY=:5
Xvfb $DISPLAY -screen 0 1024x768x16 &
sleep 2  # Donne un peu de temps pour que Xvfb démarre

# Variables globales
export WINEARCH=win64
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree=d"
export WINEPREFIX=${WINEPREFIX:-/srv/wine}

# Initialisation de Wine
wineboot -i
winecfg -v win10

# Installation de dépendances avec winetricks
winetricks -q corefonts
winetricks sound=disabled
winetricks -q vcrun2019
winetricks -q --force dotnet48
