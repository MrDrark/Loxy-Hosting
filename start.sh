#!/bin/bash
set -euo pipefail

SERVER_BIN="./samp03svr"
LOG_DIR="./logs"

info() { echo "[start.sh] $*"; }

# --- Limpar logs antigos ---
if [ -d "$LOG_DIR" ]; then
    info "Removendo logs antigos..."
    rm -rf "$LOG_DIR"
fi
rm -f ./samp.log ./server_log.txt 2>/dev/null || true

# --- Garantir permissão do binário ---
if [ ! -f "$SERVER_BIN" ]; then
    echo "[start.sh][ERRO] Binário $SERVER_BIN não encontrado!"
    exit 1
fi
chmod +x "$SERVER_BIN"

# --- Iniciar o servidor ---
info "Iniciando servidor..."
exec "$SERVER_BIN" "$@"
