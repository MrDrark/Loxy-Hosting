#!/bin/bash

# Caminho para o executável do servidor
SERVER_PATH="./samp03svr"
LOG_DIR="./logs"
SAMP_TAR="samp037svr_R2-2-1.tar.gz"
GITHUB_URL="https://github.com/sampbr/start/raw/main/$SAMP_TAR"

# Remover a pasta logs se existir
if [ -d "$LOG_DIR" ]; then
    echo "Removendo pasta logs..."
    rm -rf "$LOG_DIR"
fi

# Verificar se o arquivo samp03svr existe, senão baixar
if [ ! -f "$SERVER_PATH" ]; then
    echo "Arquivo $SERVER_PATH não encontrado. Tentando baixar do GitHub..."

    # Testar se o ambiente permite downloads antes de executar o curl
    if ! curl --silent --head --fail "$GITHUB_URL" > /dev/null; then
        echo "Falha ao conectar ao GitHub. Verifique sua conexão ou permissões."
        exit 1
    fi

    # Baixar o tar.gz do GitHub
    curl -L "$GITHUB_URL" -o "$SAMP_TAR"

    # Extrair o conteúdo
    tar -xzf "$SAMP_TAR" --strip-components=1
    rm "$SAMP_TAR"

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
