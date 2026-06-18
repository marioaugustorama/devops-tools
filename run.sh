#!/bin/bash
set -euo pipefail

WORKSPACE_DIR="$(pwd)"
WORKSPACE_AUTO_SYNC="${DEVOPS_WORKSPACE_AUTO_SYNC:-1}"
WORKSPACE_FIX_PERMS="${DEVOPS_WORKSPACE_FIX_PERMS:-1}"

workspace_log() {
    printf '%s\n' "$*" >&2
}

fix_workspace_permissions() {
    local path

    for path in run.sh run2.sh run-dev.sh run_all.sh update-motd.sh update_bashrc; do
        if [ -f "$WORKSPACE_DIR/$path" ]; then
            chmod +x "$WORKSPACE_DIR/$path" 2>/dev/null || true
        fi
    done

    if [ -d "$WORKSPACE_DIR/bin" ]; then
        find "$WORKSPACE_DIR/bin" -maxdepth 1 -type f -exec chmod +x {} + 2>/dev/null || true
    fi
}

sync_workspace_from_git() {
    command -v git >/dev/null 2>&1 || return 0
    git -C "$WORKSPACE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

    if ! git -C "$WORKSPACE_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        workspace_log "Aviso: sem upstream git em $WORKSPACE_DIR; ignorando atualização automática."
        return 0
    fi

    if ! git -C "$WORKSPACE_DIR" diff --quiet --ignore-submodules -- 2>/dev/null || \
       ! git -C "$WORKSPACE_DIR" diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
        workspace_log "Aviso: checkout com mudanças locais em $WORKSPACE_DIR; ignorando git pull automático."
        return 0
    fi

    git -C "$WORKSPACE_DIR" fetch --prune --quiet 2>/dev/null || {
        workspace_log "Aviso: falha ao buscar atualizações git em $WORKSPACE_DIR; seguindo com a versão local."
        return 0
    }

    local behind
    behind="$(git -C "$WORKSPACE_DIR" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)"
    if [ "${behind:-0}" -le 0 ]; then
        return 0
    fi

    workspace_log "Atualizando checkout local em $WORKSPACE_DIR com ${behind} commit(s) novo(s)..."
    if git -C "$WORKSPACE_DIR" pull --ff-only --quiet; then
        workspace_log "Checkout local atualizado."
    else
        workspace_log "Aviso: git pull --ff-only falhou; seguindo com a versão local."
    fi
}

if [ "$WORKSPACE_AUTO_SYNC" = "1" ]; then
    sync_workspace_from_git
fi

if [ "$WORKSPACE_FIX_PERMS" = "1" ]; then
    fix_workspace_permissions
fi

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
RUN_CONTAINER_NAME="${DEVOPS_CONTAINER_NAME:-devops-tools}"
PKG_STATE_DIR="${PKG_STATE_DIR:-$(pwd)/pkg_state}"
VPN_CONFIG_DIR="${VPN_CONFIG_DIR:-$(pwd)/vpn-configs}"
OVPN_CONFIG_DIR="${OVPN_CONFIG_DIR:-$(pwd)/openvpn-configs}"
WG_KEYS_DIR="${WG_KEYS_DIR:-$(pwd)/wireguard-keys}"
ENABLE_WIREGUARD=${ENABLE_WIREGUARD:-1}
ENABLE_WG_FORWARDING=${ENABLE_WG_FORWARDING:-0}
DEVOPS_DNS=${DEVOPS_DNS:-}
DEVOPS_DNS_SEARCH=${DEVOPS_DNS_SEARCH:-}
DEVOPS_DNS_AUTO=${DEVOPS_DNS_AUTO:-1}
DEVOPS_DOCKER_CONTEXT="${DEVOPS_DOCKER_CONTEXT:-${DOCKER_CONTEXT:-}}"
DEVOPS_DOCKER_CONTEXT_PROMPT="${DEVOPS_DOCKER_CONTEXT_PROMPT:-1}"
DEVOPS_REMOTE_VOLUME_PREFIX="${DEVOPS_REMOTE_VOLUME_PREFIX:-$RUN_CONTAINER_NAME}"
PKG_BIN_VOLUME="${PKG_BIN_VOLUME:-${DEVOPS_REMOTE_VOLUME_PREFIX}-pkg-bin}"

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
    echo "  Env: DEVOPS_DOCKER_CONTEXT=<nome> Define o docker context sem prompt"
    echo "  Env: DEVOPS_DOCKER_CONTEXT_PROMPT=0 Desativa o menu de contextos"
    echo "  Env: DEVOPS_CONTAINER_NAME=<nome> Nome do container para iniciar/conectar"
    echo "  Env: DEVOPS_REMOTE_VOLUME_PREFIX=<nome> Prefixo dos volumes em contexto remoto"
    echo "  Env: PKG_BIN_VOLUME=<nome> Volume nomeado para /var/lib/devops-pkg/bin"
    echo "  Env: DEVOPS_WORKSPACE_AUTO_SYNC=0|1 Atualiza o checkout local via git pull --ff-only"
    echo "  Env: DEVOPS_WORKSPACE_FIX_PERMS=0|1 Corrige permissões executáveis do workspace"
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

docker_context_exists() {
    local wanted="$1"
    local context

    while IFS= read -r context; do
        [ "$context" = "$wanted" ] && return 0
    done < <(docker context ls --format '{{.Name}}' 2>/dev/null || true)

    return 1
}

docker_context_host() {
    local context="$1"
    docker context inspect "$context" --format '{{.Endpoints.docker.Host}}' 2>/dev/null || true
}

docker_context_is_remote() {
    local context="$1"
    local host

    host="$(docker_context_host "$context")"
    case "$host" in
        ""|unix://*|npipe://*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

docker_context_scope_label() {
    local context="$1"

    if docker_context_is_remote "$context"; then
        printf 'remoto'
    else
        printf 'local'
    fi
}

find_running_devops_container() {
    local context="$1"
    local name running
    local -a candidates

    if [ -n "${DEVOPS_CONTAINER_NAME:-}" ]; then
        candidates=("$DEVOPS_CONTAINER_NAME")
    else
        candidates=("devops-tools" "devops-tools-daemon")
    fi

    for name in "${candidates[@]}"; do
        running="$(docker --context "$context" container inspect -f '{{.State.Running}}' "$name" 2>/dev/null || true)"
        if [ "$running" = "true" ]; then
            printf '%s\n' "$name"
            return 0
        fi
    done

    return 1
}

find_existing_devops_container() {
    local context="$1"
    local name exists
    local -a candidates

    if [ -n "${DEVOPS_CONTAINER_NAME:-}" ]; then
        candidates=("$DEVOPS_CONTAINER_NAME")
    else
        candidates=("devops-tools" "devops-tools-daemon")
    fi

    for name in "${candidates[@]}"; do
        exists="$(docker --context "$context" container inspect -f '{{.Name}}' "$name" 2>/dev/null || true)"
        if [ -n "$exists" ]; then
            printf '%s\n' "$name"
            return 0
        fi
    done

    return 1
}

select_docker_context_numeric() {
    local default_context="$1"
    shift
    local contexts=("$@")
    local selected choice context index

    echo "Docker contexts encontrados:" >&2
    index=1
    for context in "${contexts[@]}"; do
        if [ "$context" = "$default_context" ]; then
            printf '  %d) %s (atual, %s)\n' "$index" "$context" "$(docker_context_scope_label "$context")" >&2
        else
            printf '  %d) %s (%s)\n' "$index" "$context" "$(docker_context_scope_label "$context")" >&2
        fi
        index=$((index + 1))
    done

    while true; do
        printf 'Selecione o docker context [%s]: ' "$default_context" >&2
        IFS= read -r choice || {
            printf '%s\n' "$default_context"
            return
        }

        if [ -z "$choice" ]; then
            selected="$default_context"
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#contexts[@]}" ]; then
            selected="${contexts[$((choice - 1))]}"
        else
            selected="$choice"
        fi

        if docker_context_exists "$selected"; then
            printf '%s\n' "$selected"
            return
        fi

        echo "Contexto inválido: $selected" >&2
    done
}

select_docker_context() {
    local contexts=()
    local current default_context

    if [ -n "$DEVOPS_DOCKER_CONTEXT" ]; then
        printf '%s\n' "$DEVOPS_DOCKER_CONTEXT"
        return
    fi

    mapfile -t contexts < <(docker context ls --format '{{.Name}}' 2>/dev/null | awk 'NF' || true)
    if [ "${#contexts[@]}" -le 1 ] || [ "$DEVOPS_DOCKER_CONTEXT_PROMPT" = "0" ] || [ ! -t 0 ]; then
        printf 'default\n'
        return
    fi

    current="$(docker context show 2>/dev/null || true)"
    default_context="$current"
    if [ -z "$default_context" ] || ! docker_context_exists "$default_context"; then
        default_context="default"
    fi

    select_docker_context_numeric "$default_context" "${contexts[@]}"
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
    local docker_context
    local remote_context=0
    local existing_container
    local running_container
    local -a docker_cmd

    docker_context="$(select_docker_context)"
    docker_cmd=(docker --context "$docker_context")
    echo "Usando docker context: $docker_context"

    running_container="$(find_running_devops_container "$docker_context" || true)"
    if [ -n "$running_container" ]; then
        echo "Container '$running_container' já está rodando; conectando..."
        if [ "$#" -gt 0 ]; then
            exec "${docker_cmd[@]}" exec -it "$running_container" "$@"
        fi
        exec "${docker_cmd[@]}" exec -it "$running_container" bash
    fi

    existing_container="$(find_existing_devops_container "$docker_context" || true)"
    if [ -n "$existing_container" ]; then
        echo "Container '$existing_container' existe, mas não está rodando; iniciando e conectando..."
        "${docker_cmd[@]}" start "$existing_container" >/dev/null
        if [ "$#" -gt 0 ]; then
            exec "${docker_cmd[@]}" exec -it "$existing_container" "$@"
        fi
        exec "${docker_cmd[@]}" exec -it "$existing_container" bash
    fi

    if docker_context_is_remote "$docker_context"; then
        remote_context=1
        echo "Nenhum container devops-tools rodando no contexto remoto; iniciando com volumes nomeados remotos..."
    fi

    if [ "$remote_context" -eq 0 ]; then
        mkdir -p home backup logs "$PKG_STATE_DIR" "$VPN_CONFIG_DIR" "$OVPN_CONFIG_DIR" "$WG_KEYS_DIR"
    fi

    docker_flags=(
        --name "$RUN_CONTAINER_NAME"
        --init
        --privileged
        -it --tty --rm
        -u "$USER_ID:$GROUP_ID"
        --group-add "$DOCKER_GID"
        -v /var/run/docker.sock:/var/run/docker.sock
        -e LOCAL_USER_ID="$USER_ID"
        -e LOCAL_GROUP_ID="$GROUP_ID"
        -e APP_VERSION="$VERSION"
        -p "$IP_BIND:$PORTS"
    )

    if [ "$remote_context" -eq 1 ]; then
        docker_flags+=(
            -v "${DEVOPS_REMOTE_VOLUME_PREFIX}-home:/tools"
            -v "${DEVOPS_REMOTE_VOLUME_PREFIX}-backup:/backup"
            -v "${DEVOPS_REMOTE_VOLUME_PREFIX}-logs:/var/log"
            -v "${DEVOPS_REMOTE_VOLUME_PREFIX}-pkg-state:/var/lib/devops-pkg"
            -v "${PKG_BIN_VOLUME}:/var/lib/devops-pkg/bin"
            -v "${DEVOPS_REMOTE_VOLUME_PREFIX}-wireguard:/etc/wireguard"
            -v "${DEVOPS_REMOTE_VOLUME_PREFIX}-openvpn:/etc/openvpn"
            -v "${DEVOPS_REMOTE_VOLUME_PREFIX}-wireguard-keys:/etc/wireguard/keys"
        )
    else
        docker_flags+=(
            -v "$(pwd)/home:/tools"
            -v "$HOME/.kube:/tools/.kube"
            -v "$(pwd)/backup:/backup"
            -v "$(pwd)/logs:/var/log"
            -v "$PKG_STATE_DIR:/var/lib/devops-pkg"
            -v "${PKG_BIN_VOLUME}:/var/lib/devops-pkg/bin"
            -v "$VPN_CONFIG_DIR:/etc/wireguard"
            -v "$OVPN_CONFIG_DIR:/etc/openvpn"
            -v "$WG_KEYS_DIR:/etc/wireguard/keys"
        )
    fi

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
    if [ "$remote_context" -eq 0 ] && [ -f "$(pwd)/entrypoint.sh" ]; then
        docker_flags+=(-v "$(pwd)/entrypoint.sh:/entrypoint.sh:ro")
    fi
    if [ "$remote_context" -eq 0 ] && [ -f "$(pwd)/update-motd.sh" ]; then
        docker_flags+=(-v "$(pwd)/update-motd.sh:/usr/local/bin/update-motd.sh:ro")
    fi

    # Propaga flags de controle de auto-restauração/manifestos quando definidos
    for var in PKG_AUTO_RESTORE PKG_LAZY_INSTALL PKG_INDEX PKG_AUTO_LIST PKG_CACHE_DIR PKG_CACHE_ENABLED; do
        if [ -n "${!var-}" ]; then
            docker_flags+=(-e "$var=${!var}")
        fi
    done

    if [ "$remote_context" -eq 0 ] && [ -d "/mnt/sdb/backup" ]; then
        docker_flags+=(-v "/mnt/sdb/backup:/devtools_backup")
    fi

    if [ "${ENABLE_WIREGUARD}" -eq 1 ]; then
        docker_flags+=(--device /dev/net/tun --cap-add=NET_ADMIN)
        if [ "${ENABLE_WG_FORWARDING}" -eq 1 ]; then
            docker_flags+=(--sysctl net.ipv4.ip_forward=1 --sysctl net.ipv6.conf.all.forwarding=1)
        fi
    fi

    "${docker_cmd[@]}" run "${docker_flags[@]}" "$IMAGE_NAME:$IMAGE_TAG" "$@"
}

# Verificar se a opção de ajuda foi solicitada (tolerante a ausência de args)
if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Executar a função 'run'
run "$@"
