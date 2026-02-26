#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
DOCTL_BIN="doctl"
DOCTL_VERSION="${DOCTL_VERSION:-1.146.0}"
DOCTL_TAR="doctl-${DOCTL_VERSION}-linux-amd64.tar.gz"
DOCTL_URL="https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/${DOCTL_TAR}"

# Baixa o arquivo do doctl
echo "Baixando doctl..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$DOCTL_TAR" "$DOCTL_URL" || error_exit "Falha ao baixar o doctl"

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

echo "Instalação do doctl ${DOCTL_VERSION} concluída com sucesso."
