#!/bin/bash
set -euo pipefail
source /usr/local/bin/utils.sh

echo "Instalando wireguard-tools (wg/wg-quick)..."
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wireguard-tools || error_exit "Falha ao instalar wireguard-tools"
echo "wireguard-tools instalado com sucesso."
