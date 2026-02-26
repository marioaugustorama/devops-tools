#!/bin/bash
set -euo pipefail

source /usr/local/bin/utils.sh

RCLONE_VERSION="${RCLONE_VERSION:-v1.73.0}"

FILENAME="rclone-${RCLONE_VERSION}-linux-amd64.zip"
DOWNLOAD_URL="https://downloads.rclone.org/${RCLONE_VERSION}/${FILENAME}"

curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$FILENAME" "${DOWNLOAD_URL}" || error_exit "Falha ao baixar o rclone"
unzip -o "$FILENAME" || error_exit "Falha ao extrair o rclone"
install -o root -g root -m 0755 "rclone-${RCLONE_VERSION}-linux-amd64/rclone" /usr/local/bin || error_exit "Falha ao instalar o rclone"
rm -rf "$FILENAME" "rclone-${RCLONE_VERSION}-linux-amd64"

echo "rclone ${RCLONE_VERSION} instalado com sucesso."
