#!/bin/bash
set -euo pipefail
source /usr/local/bin/utils.sh

echo "Instalando OpenVPN..."
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openvpn || error_exit "Falha ao instalar openvpn"
echo "OpenVPN instalado com sucesso."
