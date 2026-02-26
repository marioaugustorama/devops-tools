#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define a URL para o binário do MinIO Client (mc)
MC_URL="https://dl.min.io/client/mc/release/linux-amd64/mc"
MC_PATH="/usr/local/bin/mc"

# Baixa o binário do MinIO Client
echo "Baixando MinIO Client (mc)..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o mc "$MC_URL" || error_exit "Falha ao baixar o MinIO Client"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "mc" ]; then
    error_exit "O binário do MinIO Client não foi encontrado."
fi

# Instala o MinIO Client
echo "Instalando MinIO Client (mc)..."
install -o root -g root -m 0755 mc "$MC_PATH" || error_exit "Falha ao instalar o MinIO Client"

# Limpeza
echo "Limpando arquivos temporários..."
rm -f mc || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do MinIO Client (mc) concluída com sucesso."
