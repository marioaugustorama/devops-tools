#!/bin/bash
set -euo pipefail

# Define variáveis
AZ_CLI_INSTALL_URL="https://aka.ms/InstallAzureCLIDeb"
AZURE_CLI_VERSION="${AZURE_CLI_VERSION:-2.83.0}"
AZCOPY_VERSION="${AZCOPY_VERSION:-10.32.1}"
AZCOPY_TAR="azcopy_linux_amd64_${AZCOPY_VERSION}.tar.gz"
AZCOPY_DOWNLOAD_URL="https://github.com/Azure/azure-storage-azcopy/releases/download/v${AZCOPY_VERSION}/${AZCOPY_TAR}"
AZCOPY_BIN="/usr/local/bin/azcopy"

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Instala o Azure CLI (pinado por versão com fallback para método oficial)
if command -v az >/dev/null 2>&1; then
    echo "Azure CLI já instalado: $(az version 2>/dev/null | head -n1 || true)"
else
    UBUNTU_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME:-jammy}")"
    AZ_DEB="azure-cli_${AZURE_CLI_VERSION}-1~${UBUNTU_CODENAME}_all.deb"
    AZ_DEB_URL="https://packages.microsoft.com/repos/azure-cli/pool/main/a/azure-cli/${AZ_DEB}"

    echo "Tentando instalar Azure CLI ${AZURE_CLI_VERSION}..."
    if curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$AZ_DEB" "$AZ_DEB_URL"; then
        apt-get update -qq || true
        apt-get install -y --no-install-recommends ./"$AZ_DEB" || {
            apt-get install -f -y
            apt-get install -y --no-install-recommends ./"$AZ_DEB"
        }
        rm -f "$AZ_DEB"
    else
        echo "Aviso: pacote pinado não disponível; usando instalador oficial."
        AZ_INSTALL_SCRIPT="/tmp/install-azure-cli.sh"
        curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$AZ_INSTALL_SCRIPT" "$AZ_CLI_INSTALL_URL" || error_exit "Falha ao baixar instalador oficial Azure CLI"
        bash "$AZ_INSTALL_SCRIPT" || error_exit "Falha ao instalar o Azure CLI"
        rm -f "$AZ_INSTALL_SCRIPT"
    fi
fi

# Baixa o AzCopy
echo "Baixando AzCopy..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$AZCOPY_TAR" "$AZCOPY_DOWNLOAD_URL" || error_exit "Falha ao baixar o AzCopy"

# Extrai o AzCopy e detecta o nome do diretório
echo "Extraindo AzCopy..."
tar -xzvf "$AZCOPY_TAR" || error_exit "Falha ao extrair o AzCopy"

# Obtém o nome do diretório extraído.
# Evita pipeline com head sob pipefail (pode retornar 141 por SIGPIPE).
AZCOPY_DIR=$(tar -tzf "$AZCOPY_TAR" | awk -F/ 'NR==1{print $1; exit}')

# Verifica se o diretório foi encontrado
if [[ -z "$AZCOPY_DIR" ]]; then
    error_exit "Não foi possível encontrar o diretório extraído"
fi

# Instala o AzCopy
echo "Instalando AzCopy..."
install -o root -g root -m 0755 $AZCOPY_DIR/azcopy $AZCOPY_BIN || error_exit "Falha ao instalar o AzCopy"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$AZCOPY_TAR" "$AZCOPY_DIR" || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação concluída com sucesso."
