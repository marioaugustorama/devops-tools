#!/bin/bash
set -euo pipefail

# Permite override via env: DEVOPS_IMAGE e DEVOPS_TAG
IMAGE_NAME=${DEVOPS_IMAGE:-marioaugustorama/devops-tools}

# Versão do app (para APP_VERSION)
VERSION=$(cat version 2>/dev/null || echo "")
if [ -z "$VERSION" ]; then
    VERSION="unknown"
fi
DEFAULT_TAG=$VERSION
if [ "$DEFAULT_TAG" = "unknown" ]; then
    DEFAULT_TAG="latest"
fi
IMAGE_TAG=${DEVOPS_TAG:-$DEFAULT_TAG}

# Mapeamento de portas (faixa consistente)
PORTS="30000-30005:30000-30005"

USER_ID=$(id -u)
GROUP_ID=$(id -g)
IP_BIND="0.0.0.0"
DOCKER_GID=$(stat -c %g /var/run/docker.sock 2>/dev/null || echo 0)
PKG_STATE_DIR="${PKG_STATE_DIR:-$(pwd)/pkg_state}"
VPN_CONFIG_DIR="${VPN_CONFIG_DIR:-$(pwd)/vpn-configs}"
WG_KEYS_DIR="${WG_KEYS_DIR:-$(pwd)/wireguard-keys}"
ENABLE_WIREGUARD=${ENABLE_WIREGUARD:-1}
ENABLE_WG_FORWARDING=${ENABLE_WG_FORWARDING:-0}


show_help() {
    echo "Uso: $0 [opções] [comando]"
    echo
    echo "Opções:"
    echo "  --help, -h             Mostrar esta mensagem de ajuda e sair"
    echo
    echo "Comandos:"
    echo "  Se nenhum comando for fornecido, um shell interativo (bash) será iniciado."
    echo "  Qualquer comando fornecido será executado dentro do container Docker."
    echo
    echo "Exemplos:"
    echo "  $0               Inicia um shell interativo (bash) dentro do container Docker."
    echo "  $0 backup        Executa o script backup dentro do container Docker."
}


run() {
    mkdir -p home backup logs "$PKG_STATE_DIR" "$VPN_CONFIG_DIR" "$WG_KEYS_DIR"

    docker_flags=(
        --name devops-tools
        --privileged
        -it --tty --rm
        -u "$USER_ID:$GROUP_ID"
        --group-add "$DOCKER_GID"
        -v /var/run/docker.sock:/var/run/docker.sock
        -v "$(pwd)/home:/tools"
        -v "$HOME/.kube:/tools/.kube"
        -v "$(pwd)/backup:/backup"
        -v "$(pwd)/logs:/var/log"
        -v "$PKG_STATE_DIR:/var/lib/devops-pkg"
        -v "$VPN_CONFIG_DIR:/etc/wireguard"
        -v "$WG_KEYS_DIR:/etc/wireguard/keys"
        -e LOCAL_USER_ID="$USER_ID"
        -e LOCAL_GROUP_ID="$GROUP_ID"
        -e APP_VERSION="$VERSION"
        -p "$IP_BIND:$PORTS"
    )

    # Usa entrypoint local atualizado se existir (evita precisar rebuildar imagem para ajustes)
    if [ -f "$(pwd)/entrypoint.sh" ]; then
        docker_flags+=(-v "$(pwd)/entrypoint.sh:/entrypoint.sh:ro")
    fi

    # Propaga flags de controle de auto-restauração/manifestos quando definidos
    for var in PKG_AUTO_RESTORE PKG_LAZY_INSTALL PKG_INDEX PKG_AUTO_LIST; do
        if [ -n "${!var-}" ]; then
            docker_flags+=(-e "$var=${!var}")
        fi
    done

    if [ -d "/mnt/sdb/backup" ]; then
        docker_flags+=(-v "/mnt/sdb/backup:/devtools_backup")
    fi

    if [ "${ENABLE_WIREGUARD}" -eq 1 ]; then
        docker_flags+=(--device /dev/net/tun --cap-add=NET_ADMIN)
        if [ "${ENABLE_WG_FORWARDING}" -eq 1 ]; then
            docker_flags+=(--sysctl net.ipv4.ip_forward=1 --sysctl net.ipv6.conf.all.forwarding=1)
        fi
    fi

    docker run "${docker_flags[@]}" "$IMAGE_NAME:$IMAGE_TAG" "$@"
}

# Verificar se a opção de ajuda foi solicitada (tolerante a ausência de args)
if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Executar a função 'run'
run "$@"
