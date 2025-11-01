#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
FILE_NAME="eksctl_linux_amd64.tar.gz"

# URL de download para o arquivo
DOWNLOAD_URL="https://github.com/eksctl-io/eksctl/releases/latest/download/${FILE_NAME}"

# Baixa o arquivo
echo "Baixando eksctl..."
curl -sLO "$DOWNLOAD_URL" || error_exit "Falha ao baixar o eksctl"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "$FILE_NAME" ]; then
    error_exit "O arquivo $FILE_NAME não foi encontrado."
fi

# Extrai o arquivo
echo "Extraindo o arquivo TAR..."
tar xzvf "$FILE_NAME" || error_exit "Falha ao extrair o arquivo TAR"

# Verifica se o binário foi extraído
if [ ! -f "eksctl" ]; then
    error_exit "O binário 'eksctl' não foi encontrado após a extração."
fi

# Instala o eksctl
echo "Instalando eksctl..."
install -o root -g root -m 0755 eksctl /usr/local/bin/ || error_exit "Falha ao instalar o eksctl"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$FILE_NAME" eksctl || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do eksctl concluída com sucesso."
