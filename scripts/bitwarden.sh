#!/bin/bash
set -euo pipefail

source /usr/local/bin/utils.sh

BW_VERSION="${BW_VERSION:-1.22.1}"
ZIP_NAME="bw-linux-${BW_VERSION}.zip"
ZIP_URL="https://github.com/bitwarden/cli/releases/download/v${BW_VERSION}/${ZIP_NAME}"
SHA_NAME="bw-linux-sha256-${BW_VERSION}.txt"
SHA_URL="https://github.com/bitwarden/cli/releases/download/v${BW_VERSION}/${SHA_NAME}"
STRICT="${STRICT_CHECKSUM:-1}"

echo "Baixando Bitwarden CLI (bw) ${BW_VERSION}..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$ZIP_NAME" "$ZIP_URL" || error_exit "Falha ao baixar ${ZIP_NAME}"

if [ "$STRICT" != "0" ]; then
    echo "Baixando checksums do Bitwarden CLI..."
    curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$SHA_NAME" "$SHA_URL" || error_exit "Falha ao baixar ${SHA_NAME}"

    expected_sha=$(awk -v f="$ZIP_NAME" '$0 ~ f {print $1}' "$SHA_NAME" | head -n1 | tr -d '[:space:]')
    if [ -z "$expected_sha" ]; then
        expected_sha=$(awk -F'= ' -v f="$ZIP_NAME" '$0 ~ f {print $2}' "$SHA_NAME" | head -n1 | tr -d '[:space:]')
    fi
    if [ -z "$expected_sha" ]; then
        # Alguns releases publicam apenas o hash puro (sem nome do arquivo).
        expected_sha=$(tr -d '\r\n[:space:]' < "$SHA_NAME")
    fi
    expected_sha=$(echo "$expected_sha" | tr '[:upper:]' '[:lower:]')
    [[ "${#expected_sha}" -eq 64 ]] || error_exit "Checksum esperado inválido para ${ZIP_NAME}"
    echo "${expected_sha}  ${ZIP_NAME}" | sha256sum -c - || error_exit "Checksum inválido para ${ZIP_NAME}"
fi

echo "Extraindo Bitwarden CLI..."
unzip -o "$ZIP_NAME" bw || error_exit "Falha ao extrair ${ZIP_NAME}"
[ -f "bw" ] || error_exit "Binário bw não encontrado após extração."

echo "Instalando Bitwarden CLI..."
install -o root -g root -m 0755 bw /usr/local/bin/bw || error_exit "Falha ao instalar bw"

rm -f bw "$ZIP_NAME" "$SHA_NAME"

echo "Bitwarden CLI ${BW_VERSION} instalado com sucesso."
