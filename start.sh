#!/bin/bash
set -euo pipefail

WORKDIR="$(pwd)"
SERVER_BIN="$WORKDIR/samp03svr"
LOG_DIR="$WORKDIR/logs"
TMPDIR="/tmp/samp03_extract"

info() { echo "[start.sh] $*"; }

# --- Limpar logs antigos ---
if [ -d "$LOG_DIR" ]; then
    info "Removendo logs antigos..."
    rm -rf "$LOG_DIR"
fi
rm -f "$WORKDIR/samp.log" "$WORKDIR/server_log.txt" 2>/dev/null || true

# --- Baixar e extrair binário se não existir ---
if [ ! -f "$SERVER_BIN" ]; then
    info "Binário não encontrado. Baixando pacote completo..."

    # Baixar o zip
    curl -fsSL https://github.com/MrDrark/Loxy-Hosting/raw/refs/heads/main/samp03.zip -o /tmp/samp03.zip

    # Criar pasta temporária e extrair
    mkdir -p "$TMPDIR"
    unzip -oq /tmp/samp03.zip -d "$TMPDIR"

    # Copiar binário e arquivos pro diretório do servidor
    cp -r "$TMPDIR"/* "$WORKDIR"/
    rm -rf "$TMPDIR" /tmp/samp03.zip

    info "Binário e arquivos extraídos com sucesso!"
fi

# --- Garantir permissões do binário ---
chmod +x "$SERVER_BIN"

# --- Iniciar o servidor ---
info "Iniciando servidor..."
exec "$SERVER_BIN"
