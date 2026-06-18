#!/bin/bash
set -euo pipefail

detect_primary_ip() {
    local ip

    ip="$(hostname -I 2>/dev/null | awk '{
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $i !~ /^127\./) {
                print $i
                exit
            }
        }
    }' || true)"
    if [ -n "${ip:-}" ]; then
        printf '%s\n' "$ip"
        return 0
    fi

    ip="$(ip -o -4 addr show scope global 2>/dev/null | awk 'NR==1 {split($4, parts, "/"); print parts[1]; exit}' || true)"
    if [ -n "${ip:-}" ]; then
        printf '%s\n' "$ip"
        return 0
    fi

    ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{
        for (i = 1; i <= NF; i++) {
            if ($i == "src" && $(i + 1) != "") {
                print $(i + 1)
                exit
            }
        }
    }' || true)"
    if [ -n "${ip:-}" ]; then
        printf '%s\n' "$ip"
        return 0
    fi

    ip="$(getent ahostsv4 "$(hostname)" 2>/dev/null | awk 'NR==1 && $1 !~ /^127\./ {print $1; exit}' || true)"
    if [ -n "${ip:-}" ]; then
        printf '%s\n' "$ip"
        return 0
    fi

    printf '%s\n' "N/A"
}

# Melhor esforço para identificar IP e versão visível ao usuário.
IP_ADDRESS="$(detect_primary_ip)"

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
