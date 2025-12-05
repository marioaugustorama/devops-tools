#!/bin/bash
set -euo pipefail

# Define variáveis
AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
AWSCLI_ZIP="awscli-exe-linux-x86_64.zip"

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh || { echo "Falha ao carregar /usr/local/bin/utils.sh"; exit 1; }

# Se já instalado, sai
if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI já instalado: $(aws --version 2>&1)"
    exit 0
fi

# Baixa o AWS CLI
echo "Baixando AWS CLI..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -O "$AWSCLI_URL" || error_exit "Falha ao baixar o AWS CLI"

# Verifica se o arquivo zip foi baixado corretamente
if [ ! -f "$AWSCLI_ZIP" ]; then
    error_exit "O arquivo $AWSCLI_ZIP não foi encontrado."
fi

# Extrai o arquivo ZIP
echo "Extraindo o arquivo ZIP..."
unzip -q "$AWSCLI_ZIP" || error_exit "Falha ao extrair o arquivo ZIP"

# Verifica se o diretório de instalação foi criado
if [ ! -d "aws" ]; then
    error_exit "O diretório 'aws' não foi criado após a extração."
fi

# Instala o AWS CLI
echo "Instalando AWS CLI..."
./aws/install -i /usr/local/aws-cli -b /usr/local/bin || error_exit "Falha ao instalar o AWS CLI"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$AWSCLI_ZIP" aws || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do AWS CLI concluída com sucesso: $(/usr/local/bin/aws --version 2>&1)"
