#!/bin/bash
set -euo pipefail

WORKDIR="/mnt/server"
cd "$WORKDIR" || exit 1

echo ">> Limpando logs antigos..."
rm -rf logs/*

echo ">> Iniciando o servidor SA-MP..."
exec ./samp03svr
