#!/bin/bash
set -euo pipefail

# Melhor esforço para identificar IP e versão visível ao usuário.
IP_ADDRESS=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "${IP_ADDRESS:-}" ]; then
    IP_ADDRESS="N/A"
fi

APP_VERSION_DISPLAY="${APP_VERSION:-}"
if [ -z "$APP_VERSION_DISPLAY" ] || [ "$APP_VERSION_DISPLAY" = "unknown" ]; then
    APP_VERSION_DISPLAY=$(cat /etc/version 2>/dev/null || true)
fi
if [ -z "$APP_VERSION_DISPLAY" ]; then
    APP_VERSION_DISPLAY="latest"
fi

TOOLS_WEB_PORT="${TOOLS_WEB_PORT:-${BACKUP_WEB_PORT:-30000}}"
TOOLS_WEB_LOCAL_URL="http://localhost:${TOOLS_WEB_PORT}"
TOOLS_WEB_CONTAINER_URL="http://${IP_ADDRESS}:${TOOLS_WEB_PORT}"

echo "**************************************************************"
echo "* Bem-vindo ao DevOps tools: ${APP_VERSION_DISPLAY}"
echo "* IP da interface principal: ${IP_ADDRESS}"
echo "* tools-web (host local): ${TOOLS_WEB_LOCAL_URL}"
echo "* tools-web (rede/container): ${TOOLS_WEB_CONTAINER_URL}"
echo "**************************************************************"
