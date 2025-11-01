#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
DOCTL_BIN="doctl"
REPO="digitalocean/doctl"
VERSION_PATTERN='(?<=/v)[0-9]+\.[0-9]+\.[0-9]+'

# Obtém a última versão
latest_version=$(get_latest_version "$REPO" "$VERSION_PATTERN")

if [ $? -eq 0 ]; then
    DOCTL_TAR="doctl-${latest_version#v}-linux-amd64.tar.gz"
    DOCTL_URL="https://github.com/${REPO}/releases/download/${latest_version}/${DOCTL_TAR}"

    echo "URL para download da versão ${latest_version}: $DOCTL_URL"
else
    echo "Erro ao obter a última versão."
fi

# Baixa o arquivo do doctl
echo "Baixando doctl..."
curl -LO "$DOCTL_URL" || error_exit "Falha ao baixar o doctl"

# Verifica se o arquivo tar foi baixado corretamente
if [ ! -f "$DOCTL_TAR" ]; then
    error_exit "O arquivo $DOCTL_TAR não foi encontrado."
fi

# Extrai o arquivo tar
echo "Extraindo o arquivo TAR..."
tar xzvf "$DOCTL_TAR" || error_exit "Falha ao extrair o arquivo TAR"

# Verifica se o binário doctl foi extraído
if [ ! -f "$DOCTL_BIN" ]; then
    error_exit "O binário $DOCTL_BIN não foi encontrado após a extração."
fi

# Instala o doctl
echo "Instalando doctl..."
install -o root -g root -m 0755 "$DOCTL_BIN" /usr/local/bin/ || error_exit "Falha ao instalar o doctl"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$DOCTL_TAR" "$DOCTL_BIN" || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do doctl concluída com sucesso."
