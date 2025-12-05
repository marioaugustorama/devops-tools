#!/bin/bash
set -euo pipefail

# Se já existe docker no ambiente, não tenta reinstalar
if command -v docker >/dev/null 2>&1; then
  echo "Docker já presente: $(docker --version 2>/dev/null || echo found)"
  exit 0
fi

# Instala rapidamente o cliente/daemon padrão
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

usermod -aG docker devops

# Deixa o socket para uso via group (ajustado em runtime pelo host)
