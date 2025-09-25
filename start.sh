#!/bin/bash
set -euo pipefail

# Caminho para o executável do servidor
SERVER_PATH="./samp03svr"
LOG_DIR="./logs"
SAMP_TAR="samp037svr_R2-2-1.tar.gz"
SAMP_URL="https://gta-multiplayer.cz/downloads/$SAMP_TAR"

# Remover a pasta logs se existir
if [ -d "$LOG_DIR" ]; then
    echo "Removendo pasta logs..."
    rm -rf "$LOG_DIR"
fi

# Verificar se o arquivo samp03svr existe, senão baixar
if [ ! -f "$SERVER_PATH" ]; then
    echo "Arquivo $SERVER_PATH não encontrado. Tentando baixar do site oficial..."

    # Testar se o ambiente permite downloads antes de executar o curl
    if ! curl --silent --head --fail "$SAMP_URL" > /dev/null; then
        echo "Falha ao conectar ao site oficial. Verifique sua conexão ou permissões."
        exit 1
    fi

    # Baixar o tar.gz oficial
    curl -sSL -o "$SAMP_TAR" "$SAMP_URL"

    # Extrair o conteúdo
    tar -xzf "$SAMP_TAR" --strip-components=1
    rm -f "$SAMP_TAR"

    # Verificar se o binário foi extraído
    if [ ! -f "$SERVER_PATH" ]; then
        echo "Erro: binário samp03svr não encontrado após extração!"
        exit 1
    fi

    echo "Arquivo baixado e extraído com sucesso!"
fi

# Garantir que o arquivo samp03svr tem permissão de execução
chmod +x "$SERVER_PATH"

# Iniciar o servidor e exibir saída
echo "Iniciando o servidor..."
exec "$SERVER_PATH"
