#!/bin/bash
set -euo pipefail

SERVER_PATH="./samp03svr"
LOG_DIR="./logs"

# Criar pasta de logs se não existir
mkdir -p "$LOG_DIR"

# Garantir permissões do binário
chmod +x "$SERVER_PATH"

# Mensagem
echo "Iniciando o servidor SA-MP Linux..."
exec "$SERVER_PATH"
