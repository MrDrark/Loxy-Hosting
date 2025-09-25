#!/bin/bash
set -euo pipefail

WORKDIR="$(pwd)"
SERVER_BIN="$WORKDIR/samp03svr"
LOG_DIR="$WORKDIR/logs"
PLUGINS_DIR="$WORKDIR/plugins"
RCON_ENV="${RCON_PASS:-${PASSWORD:-}}"
SERVER_ARGS="$@"

info() { echo "[start.sh] $*"; }
warn() { echo "[start.sh][WARN] $*"; }

# --- Limpar logs antigos ---
if [ -d "$LOG_DIR" ]; then
    info "Removendo logs antigos..."
    rm -rf "$LOG_DIR"
fi
rm -f "$WORKDIR/samp.log" "$WORKDIR/server_log.txt" 2>/dev/null || true

# --- Verificar/baixar binário ---
if [ ! -f "$SERVER_BIN" ]; then
    info "Binário não encontrado. Baixando..."
    curl -fsSL https://github.com/sampbr/start/raw/main/samp03svr -o "$SERVER_BIN"
    chmod 777 "$SERVER_BIN"
    info "Binário baixado com sucesso!"
fi

# --- Plugins .dll -> .so ---
mkdir -p "$PLUGINS_DIR"
dll_count=$(ls "$PLUGINS_DIR"/*.dll 2>/dev/null | wc -l)
if [ "$dll_count" -gt 0 ]; then
    warn "Renomeando plugins .dll para .so..."
    for dll in "$PLUGINS_DIR"/*.dll; do
        cp -n "$dll" "${dll%.dll}.so"
    done
fi

# --- Substituir .dll por .so no server.cfg ---
CFG="$WORKDIR/server.cfg"
if [ -f "$CFG" ]; then
    sed -i 's/\.dll/\.so/gI' "$CFG"
fi

# --- Iniciar servidor ---
info "Iniciando servidor..."
exec "$SERVER_BIN" $SERVER_ARGS
