#!/bin/bash
set -euo pipefail

# --- Variáveis ---
WORKDIR="$(pwd)"
SERVER_BIN="$WORKDIR/samp03svr"
LOG_DIR="$WORKDIR/logs"
PLUGINS_DIR="$WORKDIR/plugins"
TMPDIR="/tmp/samp03_extract"
ZIP_URL="https://raw.githubusercontent.com/MrDrark/Loxy-Hosting/main/samp03.zip"
RCON_ENV="${RCON_PASS:-${PASSWORD:-}}"
SERVER_ARGS="$@"

info() { echo "[start.sh] $*"; }
warn() { echo "[start.sh][WARN] $*"; }

# --- Preparar diretórios ---
mkdir -p "$WORKDIR" "$PLUGINS_DIR" "$TMPDIR"

# --- Limpar logs antigos ---
if [ -d "$LOG_DIR" ]; then
    info "Removendo logs antigos..."
    rm -rf "$LOG_DIR"
fi
rm -f "$WORKDIR/samp.log" "$WORKDIR/server_log.txt" 2>/dev/null || true

# --- Baixar pacote base se binário não existir ---
if [ ! -f "$SERVER_BIN" ]; then
    info "Binário não encontrado. Baixando pacote completo..."
    curl -fsSL "$ZIP_URL" -o /tmp/samp03.zip
    unzip -oq /tmp/samp03.zip -d "$TMPDIR"
    cp -r "$TMPDIR"/* "$WORKDIR"/
    rm -rf "$TMPDIR" /tmp/samp03.zip
    chmod +x "$SERVER_BIN"
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

# --- Plugins: renomear .dll -> .so ---
dll_count=$(ls "$PLUGINS_DIR"/*.dll 2>/dev/null | wc -l)
if [ "$dll_count" -gt 0 ]; then
    warn "Renomeando plugins .dll para .so..."
    for dll in "$PLUGINS_DIR"/*.dll; do
        cp -n "$dll" "${dll%.dll}.so"
    done
fi

# --- Substituir .dll por .so no server.cfg ---
if [ -f "$CFG" ]; then
    sed -i 's/\.dll/\.so/gI' "$CFG"
fi

# --- Garantir permissões do binário ---
chmod 777 "$SERVER_BIN"

# --- Iniciar servidor ---
info "Iniciando servidor..."
exec "$SERVER_BIN" $SERVER_ARGS
