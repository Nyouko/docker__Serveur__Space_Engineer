#!/bin/bash
set -euo pipefail

# Paramètres
PORT=27016           # Port du serveur (doit correspondre au port Docker exposé)
TIMEOUT=3            # Timeout de la commande en secondes

# Vérifie que le port est ouvert (en UDP)
if timeout "$TIMEOUT" bash -c "</dev/udp/127.0.0.1/$PORT"; then
    echo "[HEALTHCHECK] Port UDP $PORT ouvert"
    exit 0
else
    echo "[HEALTHCHECK] Port UDP $PORT fermé ou serveur inactif"
    exit 1
fi
