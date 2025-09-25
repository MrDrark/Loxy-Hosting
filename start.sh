#!/usr/bin/env bash
set -euo pipefail

GITHUB_ZIP_RAW="https://raw.githubusercontent.com/MrDrark/Loxy-Hosting/main/samp03.zip"
WORKDIR="$(pwd)"
TMPDIR="/tmp/samp03_extract"
RCON_ENV="${RCON_PASS:-${PASSWORD:-}}"
SERVER_ARGS="$@"

info() { echo "[start.sh] $*"; }
warn() { echo "[start.sh][WARN] $*"; }

info "Preparando ambiente..."
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

# Limpa logs antigos
rm -rf "${WORKDIR}/logs" "${WORKDIR}/samp.log" "${WORKDIR}/server_log.txt" 2>/dev/null || true

# --- Baixar pacote base ---
info "Baixando $GITHUB_ZIP_RAW..."
if curl -fsSL "$GITHUB_ZIP_RAW" -o /tmp/samp03.zip; then
    info "Extraindo..."
    unzip -oq /tmp/samp03.zip -d "$TMPDIR"
    cp -r "$TMPDIR"/* "$WORKDIR"/
    rm -rf "$TMPDIR" /tmp/samp03.zip
else
    warn "Falha ao baixar $GITHUB_ZIP_RAW, usando arquivos existentes."
fi

cd "$WORKDIR"

# --- Config server.cfg ---
CFG="./server.cfg"
if [ ! -f "$CFG" ]; then
    cat > "$CFG" <<'EOF'
# server.cfg gerado automaticamente
maxplayers 50
hostname SA-MP Server
EOF
fi

# remove porta fixa
sed -i '/^port /dI' "$CFG"

# rcon
if [ -n "$RCON_ENV" ]; then
    sed -i '/^rcon_password/dI' "$CFG"
    echo "rcon_password $RCON_ENV" >> "$CFG"
fi

# --- Plugins ---
PLUGINS_DIR="./plugins"
mkdir -p "$PLUGINS_DIR"

so_count=$(ls "$PLUGINS_DIR"/*.so 2>/dev/null | wc -l)
dll_count=$(ls "$PLUGINS_DIR"/*.dll 2>/dev/null | wc -l)

if [ "$so_count" -eq 0 ] && [ "$dll_count" -gt 0 ]; then
    warn "Sem plugins .so, renomeando .dll -> .so (pode não funcionar)."
    for dll in "$PLUGINS_DIR"/*.dll; do
        cp -n "$dll" "${dll%.dll}.so"
    done
    sed -i 's/\.dll/\.so/gI' "$CFG"
fi

# --- Binário ---
SERVER_BIN="./samp03svr"
if [ ! -x "$SERVER_BIN" ]; then
    for f in ./samp*svr*; do
        [ -f "$f" ] && mv -f "$f" "$SERVER_BIN" && break
    done
    chmod +x "$SERVER_BIN" 2>/dev/null || true
fi

if [ ! -f "$SERVER_BIN" ]; then
    echo "[start.sh][ERRO] Binário $SERVER_BIN não encontrado."
    exit 1
fi

info "Iniciando servidor na porta definida pelo painel..."
exec "$SERVER_BIN" $SERVER_ARGS
