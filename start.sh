#!/bin/bash

# Caminho para o executável do servidor
SERVER_PATH="./samp03svr"
LOG_DIR="./logs"

# Remover a pasta logs se existir
if [ -d "$LOG_DIR" ]; then
    echo "Removendo pasta logs..."
    rm -rf "$LOG_DIR"
fi

# Verificar se o arquivo samp03svr existe, senão baixar
if [ ! -f "$SERVER_PATH" ]; then
    echo "Arquivo $SERVER_PATH não encontrado. Tentando baixar..."
    
    # Testar se o ambiente permite downloads antes de executar o curl
    if ! curl --silent --head --fail https://github.com/MrDrark/Loxy-Hosting/raw/refs/heads/main/samp03.zip > /dev/null; then
        echo "Falha ao conectar ao servidor de download. Verifique sua conexão ou permissões."
        exit 1
    fi

    # Baixar o arquivo
    curl -L https://github.com/MrDrark/Loxy-Hosting/raw/refs/heads/main/samp03.zip -o "$SERVER_PATH"
    
    # Verificar se o download foi bem-sucedido
    if [ ! -f "$SERVER_PATH" ]; then
        echo "Erro ao baixar o arquivo samp03svr. O servidor pode estar sem acesso à internet."
        exit 1
    fi

    echo "Arquivo baixado com sucesso!"
fi

# Garantir que o arquivo samp03svr tem permissão 777
chmod 777 "$SERVER_PATH"

# Iniciar o servidor e exibir saída
echo "Iniciando o servidor..."
exec "$SERVER_PATH"
