#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Defina a versão e o arquivo para download
VERSION="1.9.3"
FILENAME="terraform_${VERSION}_linux_amd64.zip"
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${VERSION}/${FILENAME}"
BINARY_NAME="terraform"

echo "Baixando Terraform versão ${VERSION}..."

# Baixa o arquivo
curl -sLO "$DOWNLOAD_URL" || error_exit "Falha ao baixar o Terraform"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "$FILENAME" ]; then
    error_exit "O arquivo $FILENAME não foi encontrado."
fi

# Extrai o arquivo
echo "Extraindo o arquivo ZIP..."
unzip -o "$FILENAME" || error_exit "Falha ao extrair o arquivo ZIP"

# Verifica se o binário foi extraído
if [ ! -f "$BINARY_NAME" ]; then
    error_exit "O binário '$BINARY_NAME' não foi encontrado após a extração."
fi

# Instala o Terraform
echo "Instalando Terraform..."
install -o root -g root -m 0755 "$BINARY_NAME" /usr/local/bin/ || error_exit "Falha ao instalar o Terraform"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$FILENAME" "$BINARY_NAME" LICENSE.txt || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do Terraform concluída com sucesso."
