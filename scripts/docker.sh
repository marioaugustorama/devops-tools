#!/bin/bash
set -euo pipefail

# Se já existe docker no ambiente, não tenta reinstalar
if command -v docker >/dev/null 2>&1; then
  echo "Docker já presente: $(docker --version 2>/dev/null || echo found)"
  exit 0
fi

# Instala rapidamente o cliente/daemon padrão
DOCKER_INSTALL_SCRIPT="get-docker.sh"
DOCKER_VERSION="${DOCKER_VERSION:-}"
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$DOCKER_INSTALL_SCRIPT" https://get.docker.com
if [ -n "$DOCKER_VERSION" ]; then
  sh "$DOCKER_INSTALL_SCRIPT" --version "$DOCKER_VERSION"
else
  sh "$DOCKER_INSTALL_SCRIPT"
fi
rm -f "$DOCKER_INSTALL_SCRIPT"

usermod -aG docker devops

# Deixa o socket para uso via group (ajustado em runtime pelo host)
