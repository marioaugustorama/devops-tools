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
OVPN_CONFIG_DIR="${OVPN_CONFIG_DIR:-$(pwd)/openvpn-configs}"
WG_KEYS_DIR="${WG_KEYS_DIR:-$(pwd)/wireguard-keys}"
ENABLE_WIREGUARD=${ENABLE_WIREGUARD:-1}
ENABLE_WG_FORWARDING=${ENABLE_WG_FORWARDING:-0}
DEVOPS_DNS=${DEVOPS_DNS:-}
DEVOPS_DNS_SEARCH=${DEVOPS_DNS_SEARCH:-}
DEVOPS_DNS_AUTO=${DEVOPS_DNS_AUTO:-1}

# If PKG_STATE_DIR comes from the environment and is not writable (e.g. /var/lib/*),
# fall back to a local directory so non-root users can run the container.
if ! mkdir -p "$PKG_STATE_DIR" 2>/dev/null; then
    fallback_pkg_state_dir="$(pwd)/pkg_state"
    echo "Aviso: sem permissão para PKG_STATE_DIR='$PKG_STATE_DIR'. Usando '$fallback_pkg_state_dir'." >&2
    PKG_STATE_DIR="$fallback_pkg_state_dir"
fi


show_help() {
    echo "Uso: $0 [opções] [comando]"
    echo
    echo "Opções:"
    echo "  --help, -h             Mostrar esta mensagem de ajuda e sair"
    echo "  Env: DEVOPS_DNS=IP[,IP] DEVOPS_DNS_SEARCH=dominio[,dominio] DEVOPS_DNS_AUTO=0|1"
    echo
    echo "Comandos:"
    echo "  Se nenhum comando for fornecido, um shell interativo (bash) será iniciado."
    echo "  Qualquer comando fornecido será executado dentro do container Docker."
    echo
    echo "Exemplos:"
    echo "  $0               Inicia um shell interativo (bash) dentro do container Docker."
    echo "  $0 backup        Executa o script backup dentro do container Docker."
    echo "  $0 tools-web     Sobe serviço HTTP de utilidades no container (porta 30000)."
    echo "  $0 backup-web    Alias legado para tools-web."
}

auto_detect_dns_from_wireguard() {
    local conf dns_line token trimmed
    local -a detected_dns=()
    local -a detected_search=()

    shopt -s nullglob
    for conf in "$VPN_CONFIG_DIR"/*.conf /etc/wireguard/*.conf; do
        [ -f "$conf" ] || continue

        dns_line=$(awk -F= 'BEGIN {IGNORECASE=1} /^[[:space:]]*DNS[[:space:]]*=/{print $2; exit}' "$conf")
        [ -n "${dns_line:-}" ] || continue

        while IFS= read -r token; do
            trimmed=$(echo "$token" | xargs)
            [ -n "$trimmed" ] || continue

            if [[ "$trimmed" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [[ "$trimmed" == *:* ]]; then
                detected_dns+=("$trimmed")
            else
                detected_search+=("$trimmed")
            fi
        done < <(echo "$dns_line" | tr ',;' '\n')

        break
    done
    shopt -u nullglob

    if [ -z "$DEVOPS_DNS" ] && [ "${#detected_dns[@]}" -gt 0 ]; then
        DEVOPS_DNS=$(IFS=,; echo "${detected_dns[*]}")
    fi

    if [ -z "$DEVOPS_DNS_SEARCH" ] && [ "${#detected_search[@]}" -gt 0 ]; then
        DEVOPS_DNS_SEARCH=$(IFS=,; echo "${detected_search[*]}")
    fi
}

if [ "$DEVOPS_DNS_AUTO" = "1" ]; then
    auto_detect_dns_from_wireguard
fi


run() {
    mkdir -p home backup logs "$PKG_STATE_DIR" "$VPN_CONFIG_DIR" "$OVPN_CONFIG_DIR" "$WG_KEYS_DIR"

    docker_flags=(
        --name devops-tools
        --init
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
        -v "$OVPN_CONFIG_DIR:/etc/openvpn"
        -v "$WG_KEYS_DIR:/etc/wireguard/keys"
        -e LOCAL_USER_ID="$USER_ID"
        -e LOCAL_GROUP_ID="$GROUP_ID"
        -e APP_VERSION="$VERSION"
        -p "$IP_BIND:$PORTS"
    )

    if [ -n "$DEVOPS_DNS" ]; then
        while IFS= read -r dns_ip; do
            dns_ip=$(echo "$dns_ip" | xargs)
            [ -n "$dns_ip" ] || continue
            docker_flags+=(--dns "$dns_ip")
        done < <(echo "$DEVOPS_DNS" | tr ',;' '\n')
    fi

    if [ -n "$DEVOPS_DNS_SEARCH" ]; then
        while IFS= read -r dns_search; do
            dns_search=$(echo "$dns_search" | xargs)
            [ -n "$dns_search" ] || continue
            docker_flags+=(--dns-search "$dns_search")
        done < <(echo "$DEVOPS_DNS_SEARCH" | tr ',;' '\n')
    fi

    # Usa entrypoint local atualizado se existir (evita precisar rebuildar imagem para ajustes)
    if [ -f "$(pwd)/entrypoint.sh" ]; then
        docker_flags+=(-v "$(pwd)/entrypoint.sh:/entrypoint.sh:ro")
    fi
    if [ -f "$(pwd)/update-motd.sh" ]; then
        docker_flags+=(-v "$(pwd)/update-motd.sh:/usr/local/bin/update-motd.sh:ro")
    fi

    # Propaga flags de controle de auto-restauração/manifestos quando definidos
    for var in PKG_AUTO_RESTORE PKG_LAZY_INSTALL PKG_INDEX PKG_AUTO_LIST PKG_CACHE_DIR PKG_CACHE_ENABLED; do
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
