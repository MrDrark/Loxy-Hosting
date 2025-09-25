#!/bin/bash
set -euo pipefail

WORKDIR="/mnt/server"
cd "$WORKDIR" || exit 1

SERVER_BIN="$WORKDIR/samp03svr"
CFG_FILE="$WORKDIR/server.cfg"
LOG_DIR="$WORKDIR/logs"

# --- Limpar logs antigos ---
if [ -d "$LOG_DIR" ]; then
    echo ">> Limpando logs..."
    rm -rf "$LOG_DIR"
fi
mkdir -p "$LOG_DIR"

# --- Verificar se o binário existe ---
if [ ! -f "$SERVER_BIN" ]; then
    echo "[start.sh][ERRO] Binário $SERVER_BIN não encontrado!"
    exit 1
fi

# --- Garantir permissões corretas ---
chmod +x "$SERVER_BIN"

# --- Iniciar o servidor ---
echo ">> Iniciando o SA-MP server..."
exec "$SERVER_BIN" "$CFG_FILE"
