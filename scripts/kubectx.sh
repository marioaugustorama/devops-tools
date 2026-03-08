#!/bin/bash
set -euo pipefail
source /usr/local/bin/utils.sh

REPO="ahmetb/kubectx"
VERSION="${KUBECTX_VERSION:-v0.9.5}"
REQUESTED_BINARIES=("$@")
arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
case "$arch" in
  amd64|x86_64) ASSET_ARCH="linux_x86_64" ;;
  arm64|aarch64) ASSET_ARCH="linux_arm64" ;;
  *) error_exit "Arquitetura não suportada para kubectx/kubens: $arch" ;;
esac

resolve_asset_url() {
  local name="$1"
  local base="https://github.com/${REPO}/releases/download/${VERSION}"
  echo "${base}/${name}_${VERSION}_${ASSET_ARCH}.tar.gz"
}

download_and_install() {
  local name=$1
  local url
  url=$(resolve_asset_url "$name")
  if [ -z "$url" ] || [ "$url" = "null" ]; then
    error_exit "Não foi possível resolver URL do asset para ${name} (${ASSET_ARCH})."
  fi
  local tar
  tar=$(basename "$url")
  echo "Baixando ${name} (${tar})..."
  cache_download "$url" "$tar" "$tar"
  echo "Extraindo ${tar}..."
  tar xzf "$tar" || error_exit "Falha ao extrair ${tar}"
  if [ ! -f "$name" ]; then
    error_exit "Binário ${name} não encontrado após extração."
  fi
  echo "Instalando ${name}..."
  install -o root -g root -m 0755 "$name" "/usr/local/bin/${name}" || error_exit "Falha ao instalar ${name}"
  rm -f "$tar" "$name"
}

if [ ${#REQUESTED_BINARIES[@]} -eq 0 ]; then
  REQUESTED_BINARIES=("kubectx" "kubens")
fi

for binary in "${REQUESTED_BINARIES[@]}"; do
  case "$binary" in
    kubectx|kubens)
      download_and_install "$binary"
      ;;
    *)
      error_exit "Binário não suportado para este instalador: $binary"
      ;;
  esac
done

echo "kubectx/kubens instalados com sucesso."
