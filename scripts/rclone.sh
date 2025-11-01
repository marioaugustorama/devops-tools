#!/bin/bash

source /usr/local/bin/utils.sh

REPO="rclone/rclone"
VERSION_PATTERN='(?<=/v)[0-9]+\.[0-9]+\.[0-9]+'

latest_version=$(get_latest_version "$REPO" "$VERSION_PATTERN")

FILENAME="rclone-${latest_version}-linux-amd64.zip"

DOWNLOAD_URL="https://downloads.rclone.org/${latest_version}/${FILENAME}"

curl -LO "${DOWNLOAD_URL}"
unzip $FILENAME || error_exit "Falha ao extrair o arquivo TAR"
install -o root -g root -m 0755 rclone-${latest_version}-linux-amd64/rclone /usr/local/bin
rm -rf rclone-${latest_version}-linux-amd64.zip rclone-${latest_version}-linux-amd64