#!/bin/bash
set -euo pipefail

SERVER_PATH="./samp03svr"
LOG_DIR="./logs"

# Criar logs se não existirem
mkdir -p "$LOG_DIR"

# Garantir permissão de execução
chmod +x "$SERVER_PATH"

# Iniciar servidor
echo "Iniciando o servidor..."
exec "$SERVER_PATH"
