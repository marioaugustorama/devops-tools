#!/bin/bash
set -euo pipefail

source /usr/local/bin/utils.sh

REPO="ahmetb/kubectl-tree"
KUBECTL_TREE_VERSION="${KUBECTL_TREE_VERSION:-v0.4.6}"
API_URL="https://api.github.com/repos/${REPO}/releases/tags/${KUBECTL_TREE_VERSION}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Obtendo release ${KUBECTL_TREE_VERSION} do kubectl-tree..."
release_json=$(curl -fsSL "$API_URL") || error_exit "Não foi possível consultar a API do GitHub."
latest_tag=$(echo "$release_json" | grep -oP '"tag_name":\s*"\K[^"]+')
[ -n "$latest_tag" ] || error_exit "Não foi possível determinar a versão alvo."

if pkg_bin_exists kubectl-tree; then
    current=$(kubectl-tree version 2>/dev/null || true)
    if [[ -n "$current" && "$current" == *"$latest_tag"* ]]; then
        echo "kubectl-tree já está na versão $latest_tag"
        exit 0
    fi
fi

asset_url=$(echo "$release_json" | grep -ioE '"browser_download_url":\s*"[^"]*(linux|Linux)[^"]*(amd64|x86_64)[^"]*"' | head -n1 | cut -d'"' -f4)
[ -n "$asset_url" ] || error_exit "Não foi possível localizar binário Linux amd64 nos assets da release."

echo "Baixando kubectl-tree (${latest_tag})..."
asset_file="$TMP_DIR/asset"
curl -fL "$asset_url" -o "$asset_file" || error_exit "Falha ao baixar o asset."

echo "Extraindo..."
case "$asset_url" in
    *.tar.gz|*.tgz)
        tar -xzf "$asset_file" -C "$TMP_DIR" || error_exit "Falha ao extrair tar.gz."
        ;;
    *.zip)
        unzip -q "$asset_file" -d "$TMP_DIR" || error_exit "Falha ao extrair zip."
        ;;
    *)
        cp "$asset_file" "$TMP_DIR/" || error_exit "Falha ao preparar binário."
        ;;
esac

bin_path=$(find "$TMP_DIR" -type f -name 'kubectl-tree*' | head -n1)
[ -n "$bin_path" ] || error_exit "Binário kubectl-tree não encontrado após extração."

chmod +x "$bin_path"
echo "Instalando kubectl-tree..."
install_pkg_bin "$bin_path" kubectl-tree

echo "kubectl-tree ${latest_tag} instalado com sucesso."
