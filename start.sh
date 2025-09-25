#!/usr/bin/env bash
set -euo pipefail

# --- Configurações ---
GITHUB_ZIP_RAW="https://raw.githubusercontent.com/MrDrark/Loxy-Hosting/main/samp03.zip"
WORKDIR="$(pwd)"
TMPDIR="/tmp/samp03_extract"
RCON_ENV="${RCON_PASS:-${PASSWORD:-}}"

# --- Helpers ---
info() { echo "[SA-MP] $*"; }
warn() { echo "[SA-MP][WARN] $*"; }

# --- Preparação ---
info "Preparando ambiente..."
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

# Limpar logs antigos
rm -rf "${WORKDIR}/logs" "${WORKDIR}/samp.log" "${WORKDIR}/server_log.txt" 2>/dev/null || true

# --- Baixar pacote ---
info "Baixando servidor..."
if curl -fsSL "$GITHUB_ZIP_RAW" -o /tmp/samp03.zip; then
    info "Extraindo arquivos..."
    unzip -oq /tmp/samp03.zip -d "$TMPDIR"
    rsync -a "$TMPDIR"/ "$WORKDIR"/
    rm -rf "$TMPDIR" /tmp/samp03.zip
else
    warn "Falha ao baixar $GITHUB_ZIP_RAW, usando arquivos já existentes."
fi

cd "$WORKDIR"

# --- RCON ---
CFG="./server.cfg"
if [ ! -f "$CFG" ]; then
    cat > "$CFG" <<'EOF'
# server.cfg gerado automaticamente
maxplayers 50
port 7777
hostname SA-MP Server
EOF
fi

if [ -n "$RCON_ENV" ]; then
    sed -i "/^rcon_password/d" "$CFG"
    echo "rcon_password $RCON_ENV" >> "$CFG"
fi

# --- Plugins ---
PLUGINS_DIR="./plugins"
mkdir -p "$PLUGINS_DIR"

so_count=$(ls "$PLUGINS_DIR"/*.so 2>/dev/null | wc -l)
dll_count=$(ls "$PLUGINS_DIR"/*.dll 2>/dev/null | wc -l)

if [ "$so_count" -eq 0 ] && [ "$dll_count" -gt 0 ]; then
    warn "Sem plugins .so, convertendo nomes de .dll -> .so (pode não funcionar)."
    for dll in "$PLUGINS_DIR"/*.dll; do
        cp -n "$dll" "${dll%.dll}.so"
    done
    sed -i 's/\.dll/\.so/gI' "$CFG"
fi

# --- Binário ---
SERVER_BIN="./samp03svr"
if [ ! -x "$SERVER_BIN" ]; then
    warn "Binário $SERVER_BIN não encontrado, tentando ajustar..."
    for f in ./samp*svr*; do
        [ -f "$f" ] && mv -f "$f" "$SERVER_BIN" && break
    done
    chmod +x "$SERVER_BIN" 2>/dev/null || true
fi

if [ ! -f "$SERVER_BIN" ]; then
    echo "[SA-MP][ERRO] Não encontrei o binário do servidor."
    exit 1
fi

# --- Start ---
info "Iniciando servidor..."
exec "$SERVER_BIN"
