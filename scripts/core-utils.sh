#!/bin/bash
set -euo pipefail

source /usr/local/bin/utils.sh

declare -a missing_pkgs=()

# Ferramentas diárias do grupo core
command -v ping >/dev/null 2>&1 || missing_pkgs+=("iputils-ping")
command -v dig >/dev/null 2>&1 || missing_pkgs+=("dnsutils")
command -v ifconfig >/dev/null 2>&1 || missing_pkgs+=("net-tools")
command -v traceroute >/dev/null 2>&1 || missing_pkgs+=("traceroute")
command -v ipcalc >/dev/null 2>&1 || missing_pkgs+=("ipcalc")
command -v less >/dev/null 2>&1 || missing_pkgs+=("less")
command -v updatedb >/dev/null 2>&1 || missing_pkgs+=("plocate")

if [ "${#missing_pkgs[@]}" -eq 0 ]; then
  echo "core-utils já presente (rede, docker helpers, ipcalc, less, updatedb)."
  exit 0
fi

echo "Instalando dependências core-utils: ${missing_pkgs[*]}"
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing_pkgs[@]}" || error_exit "Falha ao instalar core-utils"
echo "core-utils instalado com sucesso."
