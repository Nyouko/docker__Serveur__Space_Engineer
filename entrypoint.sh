#!/bin/bash
set -euo pipefail

# Lancement en mode debug si demandé
[[ "${DEBUG:-0}" == "1" ]] && set -x

# Variables de chemins
SERVER_DIR="$WINEPREFIX/drive_c/spaceengineers"
CONFIG_DIR="$HOME/.config/spaceengineers"
LOG_DIR="$HOME/logs"

# Vérification que le serveur est bien présent
if [ ! -f "$SERVER_DIR/SpaceEngineersDedicated.exe" ]; then
  echo "[INFO] Fichier exécutable non trouvé. Téléchargement ou configuration manquante ?"
  exit 1
fi

# Création des dossiers nécessaires
mkdir -p "$CONFIG_DIR" "$LOG_DIR"

echo "[INFO] Lancement du serveur Space Engineers..."

# Exécution du serveur via Wine dans un environnement virtuel d'affichage
exec xvfb-run --auto-servernum \
  wine "$SERVER_DIR/SpaceEngineersDedicated.exe" \
  -noconsole \
  -path "$CONFIG_DIR" \
  >> "$LOG_DIR/server.log" 2>&1
