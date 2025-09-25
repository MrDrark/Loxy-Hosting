#!/bin/bash
set -euo pipefail

WORKDIR="$(pwd)"
SERVER_BIN="$WORKDIR/samp03svr"
LOG_DIR="$WORKDIR/logs"
TMPDIR="/tmp/samp03_extract"
ZIP_URL="https://raw.githubusercontent.com/sampbr/start/main/samp03.zip"
RCON_ENV="${RCON_PASS:-${PASSWORD:-}}"
SERVER_ARGS="$@"

info() { echo "[start.sh] $*"; }
warn() { echo "[start.sh][WARN] $*"; }

# --- Preparar ambiente ---
info "Preparando ambiente..."
mkdir -p "$WORKDIR" "$TMPDIR"

# --- Limpar logs antigos ---
if [ -d "$LOG_DIR" ]; then
    info "Removendo logs antigos..."
    rm -rf "$LOG_DIR"
fi
rm -f "$WORKDIR/samp.log" "$WORKDIR/server_log.txt" 2>/dev/null || true

# --- Baixar pacote base se binário não existir ---
if [ ! -f "$SERVER_BIN" ]; then
    info "Binário não encontrado. Tentando baixar zip completo..."
    curl -fsSL "$ZIP_URL" -o /tmp/samp03.zip
    unzip -oq /tmp/samp03.zip -d "$TMPDIR"
    cp -r "$TMPDIR"/* "$WORKDIR"/
    rm -rf "$TMPDIR" /tmp/samp03.zip
    info "Binário e arquivos extraídos com sucesso!"
fi

# --- Configurar server.cfg ---
CFG="$WORKDIR/server.cfg"
if [ ! -f "$CFG" ]; then
    cat > "$CFG" <<'EOF'
# server.cfg gerado automaticamente
maxplayers 50
hostname SA-MP Server
EOF
fi
# Remove porta fixa
sed -i '/^port /d' "$CFG" || true
# Adiciona RCON se definido
if [ -n "$RCON_ENV" ]; then
    sed -i '/^rcon_password/d' "$CFG" || true
    echo "rcon_password $RCON_ENV" >> "$CFG"
fi

# --- Plugins .dll → .so ---
PLUGINS_DIR="$WORKDIR/plugins"
mkdir -p "$PLUGINS_DIR"
so_count=$(ls "$PLUGINS_DIR"/*.so 2>/dev/null | wc -l)
dll_count=$(ls "$PLUGINS_DIR"/*.dll 2>/dev/null | wc -l)
if [ "$so_count" -eq 0 ] && [ "$dll_count" -gt 0 ]; then
    warn "Renomeando .dll para .so (Ubuntu)..."
    for dll in "$PLUGINS_DIR"/*.dll; do
        cp -n "$dll" "${dll%.dll}.so"
    done
    sed -i 's/\.dll/\.so/gI' "$CFG" || true
fi

# --- Garantir permissões do binário ---
if [ ! -f "$SERVER_BIN" ]; then
    echo "[start.sh][ERRO] Binário $SERVER_BIN não encontrado."
    exit 1
fi
chmod 777 "$SERVER_BIN"

# --- Iniciar o servidor ---
info "Iniciando servidor..."
exec "$SERVER_BIN" $SERVER_ARGS
