#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Versões padrão (podem ser sobrescritas por variáveis de ambiente)
MONGOSH_VERSION="${MONGOSH_VERSION:-2.5.8}"
MONGODB_DATABASE_TOOLS_VERSION="${MONGODB_DATABASE_TOOLS_VERSION:-100.13.0}"

# Detecta distro e arquitetura para montar o nome do pacote dos tools
UBUNTU_VERSION_ID="$(. /etc/os-release && echo "${VERSION_ID}")"
UBUNTU_VERSION_COMPACT="${UBUNTU_VERSION_ID//./}"
TOOLS_DISTRO="ubuntu${UBUNTU_VERSION_COMPACT}"
TOOLS_ARCH="$(uname -m)"
case "$TOOLS_ARCH" in
    x86_64|amd64) TOOLS_ARCH="x86_64" ;;
    aarch64|arm64) TOOLS_ARCH="arm64" ;;
    *)
        error_exit "Arquitetura não suportada para MongoDB Database Tools: ${TOOLS_ARCH}"
        ;;
esac

TMP_DIR="$(mktemp -d)"
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

########################################
# mongosh
########################################
MONGOSH_ARCHIVE_NAME="mongosh-${MONGOSH_VERSION}-linux-x64.tgz"
MONGOSH_DOWNLOAD_URL="https://downloads.mongodb.com/compass/${MONGOSH_ARCHIVE_NAME}"
MONGOSH_EXTRACTED_DIR="${TMP_DIR}/mongosh-${MONGOSH_VERSION}-linux-x64"
MONGOSH_BINARY_PATH="${MONGOSH_EXTRACTED_DIR}/bin/mongosh"

echo "Baixando mongosh versão ${MONGOSH_VERSION}..."
cache_download "$MONGOSH_DOWNLOAD_URL" "${TMP_DIR}/${MONGOSH_ARCHIVE_NAME}" "$MONGOSH_ARCHIVE_NAME"

echo "Extraindo mongosh..."
tar xzf "${TMP_DIR}/${MONGOSH_ARCHIVE_NAME}" -C "$TMP_DIR" || error_exit "Falha ao extrair o mongosh"

if [ ! -f "$MONGOSH_BINARY_PATH" ]; then
    error_exit "O binário 'mongosh' não foi encontrado após a extração."
fi

echo "Instalando mongosh..."
install -o root -g root -m 0755 "$MONGOSH_BINARY_PATH" /usr/local/bin/mongosh || error_exit "Falha ao instalar o mongosh"

########################################
# MongoDB Database Tools (mongodump/mongorestore)
########################################
TOOLS_ARCHIVE_NAME="mongodb-database-tools-${TOOLS_DISTRO}-${TOOLS_ARCH}-${MONGODB_DATABASE_TOOLS_VERSION}.tgz"
TOOLS_DOWNLOAD_URL="https://fastdl.mongodb.org/tools/db/${TOOLS_ARCHIVE_NAME}"
TOOLS_EXTRACTED_DIR="${TMP_DIR}/mongodb-database-tools-${TOOLS_DISTRO}-${TOOLS_ARCH}-${MONGODB_DATABASE_TOOLS_VERSION}"

echo "Baixando MongoDB Database Tools versão ${MONGODB_DATABASE_TOOLS_VERSION}..."
cache_download "$TOOLS_DOWNLOAD_URL" "${TMP_DIR}/${TOOLS_ARCHIVE_NAME}" "$TOOLS_ARCHIVE_NAME"

echo "Extraindo MongoDB Database Tools..."
tar xzf "${TMP_DIR}/${TOOLS_ARCHIVE_NAME}" -C "$TMP_DIR" || error_exit "Falha ao extrair MongoDB Database Tools"

if [ ! -f "${TOOLS_EXTRACTED_DIR}/bin/mongodump" ]; then
    error_exit "O binário 'mongodump' não foi encontrado após a extração."
fi

if [ ! -f "${TOOLS_EXTRACTED_DIR}/bin/mongorestore" ]; then
    error_exit "O binário 'mongorestore' não foi encontrado após a extração."
fi

echo "Instalando mongodump e mongorestore..."
install -o root -g root -m 0755 "${TOOLS_EXTRACTED_DIR}/bin/mongodump" /usr/local/bin/mongodump || error_exit "Falha ao instalar mongodump"
install -o root -g root -m 0755 "${TOOLS_EXTRACTED_DIR}/bin/mongorestore" /usr/local/bin/mongorestore || error_exit "Falha ao instalar mongorestore"

# Alias de conveniência para quem usa o termo "mongobackup"
ln -sf /usr/local/bin/mongodump /usr/local/bin/mongobackup || error_exit "Falha ao criar alias mongobackup"

echo "Instalação do MongoDB concluída com sucesso (mongosh, mongodump, mongorestore)."
