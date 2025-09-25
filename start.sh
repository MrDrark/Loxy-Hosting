#!/bin/bash
set -euo pipefail

SERVER_BIN="./samp03svr"
LOG_DIR="./logs"

# --- Limpar logs antigos ---
[ -d "$LOG_DIR" ] && rm -rf "$LOG_DIR"
rm -f samp.log server_log.txt 2>/dev/null || true

# --- Plugins .dll → .so (se existir) ---
PLUGINS_DIR="./plugins"
mkdir -p "$PLUGINS_DIR"
dll_count=$(ls "$PLUGINS_DIR"/*.dll 2>/dev/null | wc -l)
if [ "$dll_count" -gt 0 ]; then
    echo "[start.sh] Renomeando plugins .dll para .so..."
    for dll in "$PLUGINS_DIR"/*.dll; do
        cp -n "$dll" "${dll%.dll}.so"
    done
fi

# --- Substituir .dll por .so no server.cfg ---
CFG="./server.cfg"
if [ -f "$CFG" ]; then
    sed -i 's/\.dll/\.so/gI' "$CFG"
fi

# --- Verificar binário Linux ---
if [ ! -f "$SERVER_BIN" ]; then
    echo "[start.sh] Erro: Binário $SERVER_BIN não encontrado. Certifique-se de que a versão Linux foi instalada!"
    exit 1
fi

chmod +x "$SERVER_BIN"

# --- Iniciar servidor ---
echo "Iniciando servidor..."
exec "$SERVER_BIN"
