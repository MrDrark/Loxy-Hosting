#!/bin/bash
set -euo pipefail

# Caminho para o executável do servidor
SERVER_PATH="./samp03svr"
LOG_DIR="./logs"
PLUGINS_DIR="./plugins"
RCON_ENV="${RCON_PASS:-${PASSWORD:-}}"

# --- Limpar logs antigos ---
if [ -d "$LOG_DIR" ]; then
    echo "Removendo logs antigos..."
    rm -rf "$LOG_DIR"
fi
rm -f ./samp.log ./server_log.txt 2>/dev/null || true

# --- Converter plugins .dll para .so ---
mkdir -p "$PLUGINS_DIR"
dll_count=$(ls "$PLUGINS_DIR"/*.dll 2>/dev/null | wc -l)
if [ "$dll_count" -gt 0 ]; then
    echo "Renomeando plugins .dll para .so..."
    for dll in "$PLUGINS_DIR"/*.dll; do
        cp -n "$dll" "${dll%.dll}.so"
    done
fi

# --- Substituir .dll por .so no server.cfg ---
CFG="./server.cfg"
if [ -f "$CFG" ]; then
    sed -i 's/\.dll/\.so/gI' "$CFG"
fi

# --- Verificar se o arquivo samp03svr existe, senão baixar ---
if [ ! -f "$SERVER_PATH" ]; then
    echo "Arquivo $SERVER_PATH não encontrado. Tentando baixar..."
    
    if ! curl --silent --head --fail https://github.com/sampbr/start/raw/main/samp03svr > /dev/null; then
        echo "Falha ao conectar ao servidor de download. Verifique sua conexão ou permissões."
        exit 1
    fi

    curl -L https://github.com/sampbr/start/raw/main/samp03svr -o "$SERVER_PATH"
    
    if [ ! -f "$SERVER_PATH" ]; then
        echo "Erro ao baixar o arquivo samp03svr. O servidor pode estar sem acesso à internet."
        exit 1
    fi

    echo "Arquivo baixado com sucesso!"
fi

# --- Garantir que o arquivo samp03svr tem permissão 777 ---
chmod 777 "$SERVER_PATH"

# --- Iniciar o servidor ---
echo "Iniciando o servidor..."
exec "$SERVER_PATH"
