#!/bin/bash

set -euo pipefail

# Define o UID e GID do usuário corrente
USER_ID=$(id -u)
GROUP_ID=$(id -g)
PKG_STATE="/var/lib/devops-pkg/installed.list"
APT_STATE_FILE="/var/lib/devops-pkg/apt-packages.list"
PKG_AUTO_LIST="${PKG_AUTO_LIST:-/var/lib/devops-pkg/auto-install.list}"
PKG_INDEX="${PKG_INDEX:-/usr/local/scripts/packages.tsv}"
PKG_AUTO_RESTORE="${PKG_AUTO_RESTORE:-1}"
PKG_LAZY_INSTALL="${PKG_LAZY_INSTALL:-1}"
PKG_BIN_DIR="${PKG_BIN_DIR:-/var/lib/devops-pkg/bin}"
LAZY_LOADER_FILE="/tools/.pkg_add_lazy.sh"
TOOLS_WEB_AUTOSTART="${TOOLS_WEB_AUTOSTART:-${BACKUP_WEB_AUTOSTART:-1}}"
TOOLS_WEB_LOG="${TOOLS_WEB_LOG:-${BACKUP_WEB_LOG:-/var/log/tools-web.log}}"
# Compat legado (BACKUP_WEB_*)
BACKUP_WEB_AUTOSTART="${BACKUP_WEB_AUTOSTART:-$TOOLS_WEB_AUTOSTART}"
BACKUP_WEB_LOG="${BACKUP_WEB_LOG:-$TOOLS_WEB_LOG}"

try_root() {
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        "$@"
        return $?
    fi

    if command -v sudo >/dev/null 2>&1; then
        sudo -n "$@"
        return $?
    fi

    return 1
}

ensure_writable_dir() {
    local dir="$1"

    if mkdir -p "$dir" 2>/dev/null; then
        return 0
    fi

    if try_root mkdir -p "$dir"; then
        try_root chown "$USER_ID:$GROUP_ID" "$dir" 2>/dev/null || true
        try_root chmod 755 "$dir" 2>/dev/null || true
        return 0
    fi

    return 1
}

# Função para garantir que o arquivo de estado exista e seja gravável,
# com fallback para $HOME se o volume estiver somente leitura ou com owner incorreto.
ensure_state_file() {
    local target="$1"
    local fallback="$2"
    local dir
    dir=$(dirname "$target")
    if mkdir -p "$dir" 2>/dev/null && touch "$target" 2>/dev/null; then
        chown "$USER_ID:$GROUP_ID" "$target" 2>/dev/null || true
        echo "$target"
        return
    fi

    if try_root mkdir -p "$dir" && try_root touch "$target"; then
        try_root chown "$USER_ID:$GROUP_ID" "$target" 2>/dev/null || true
        echo "$target"
        return
    fi

    dir=$(dirname "$fallback")
    if mkdir -p "$dir" 2>/dev/null && touch "$fallback" 2>/dev/null; then
        chown "$USER_ID:$GROUP_ID" "$fallback" 2>/dev/null || true
        echo "$fallback"
        return
    fi

    if try_root mkdir -p "$dir" && try_root touch "$fallback"; then
        try_root chown "$USER_ID:$GROUP_ID" "$fallback" 2>/dev/null || true
        echo "$fallback"
        return
    fi

    echo "[entrypoint] Aviso: não foi possível criar arquivo de estado em $target nem em $fallback" >&2
    echo ""
}

collect_restore_packages() {
    local file pkg trimmed
    declare -A seen=()

    for file in "$PKG_STATE" "$PKG_AUTO_LIST"; do
        [ -f "$file" ] || continue

        while IFS= read -r pkg; do
            trimmed=$(echo "$pkg" | xargs)
            [ -n "$trimmed" ] || continue

            case "$trimmed" in
                \#*) continue ;;
            esac

            if [ -z "${seen[$trimmed]+x}" ]; then
                seen["$trimmed"]=1
                printf '%s\n' "$trimmed"
            fi
        done < "$file"
    done
}

# Cria o diretório home se não existir e define as permissões corretas
if [ ! -d "/tools" ]; then
    mkdir -p /tools
    # Quando o container já roda como devops, o chown pode falhar; ignore nesse caso
    chown "$USER_ID:$GROUP_ID" /tools 2>/dev/null || true
fi

# Garante permissões de estado persistente
STATE_DIR="/var/lib/devops-pkg"
if ! ensure_writable_dir "$STATE_DIR"; then
    STATE_DIR="/tmp/.devops-pkg"
    ensure_writable_dir "$STATE_DIR"
fi

if ! ensure_writable_dir "$PKG_BIN_DIR"; then
    PKG_BIN_DIR="$STATE_DIR/bin"
    ensure_writable_dir "$PKG_BIN_DIR"
fi

chmod 700 "$STATE_DIR" 2>/dev/null || true
chmod 755 "$PKG_BIN_DIR" 2>/dev/null || true
export PKG_BIN_DIR
case ":$PATH:" in
    *":$PKG_BIN_DIR:"*) ;;
    *) export PATH="$PKG_BIN_DIR:$PATH" ;;
esac

# Garante que os arquivos de estado existem e têm permissão de escrita (com fallback)
PKG_STATE=$(ensure_state_file "$PKG_STATE" "$STATE_DIR/installed.list")
APT_STATE_FILE=$(ensure_state_file "$APT_STATE_FILE" "$STATE_DIR/apt-packages.list")
PKG_AUTO_LIST=$(ensure_state_file "$PKG_AUTO_LIST" "$STATE_DIR/auto-install.list")

# Se o fallback foi retornado vazio, pula restauração de estado
if [ -z "$PKG_STATE" ] || [ -z "$APT_STATE_FILE" ]; then
    echo "[entrypoint] Aviso: não foi possível inicializar o estado de pacotes; restauração será ignorada." >&2
else
    if [ "$PKG_AUTO_RESTORE" != "0" ]; then
        if [ -n "$PKG_STATE" ] && [ -n "$APT_STATE_FILE" ]; then
            # Lista dedicada para auto-instalação do pkg_add (separada do estado de instalados)
            if [ -z "$PKG_AUTO_LIST" ]; then
                echo "[entrypoint] Aviso: lista de auto-instalação do pkg_add não inicializada." >&2
            else
                if [ ! -s "$PKG_AUTO_LIST" ]; then
                    mkdir -p "$(dirname "$PKG_AUTO_LIST")"
                    cat > "$PKG_AUTO_LIST" <<'EOF'
# Liste aqui os pacotes do pkg_add a instalar automaticamente na subida (um por linha).
# Exemplo:
# kubectl
# helm
EOF
                    chown "$USER_ID:$GROUP_ID" "$PKG_AUTO_LIST" 2>/dev/null || true
                fi

                mapfile -t PKG_LIST < <(collect_restore_packages)
                echo "[entrypoint] Restaurando pacotes via pkg_add (estado: $PKG_STATE, auto: $PKG_AUTO_LIST)..."
                if [ "${#PKG_LIST[@]}" -gt 0 ]; then
                    pkg_add install --force "${PKG_LIST[@]}" || echo "[entrypoint] Falha ao restaurar alguns pacotes" >&2
                else
                    echo "[entrypoint] Nenhum pacote listado para restaurar via pkg_add."
                fi
            fi

            if [ ! -s "$APT_STATE_FILE" ]; then
                mkdir -p "$(dirname "$APT_STATE_FILE")"
                cat > "$APT_STATE_FILE" <<'EOF'
# Liste aqui os pacotes apt a restaurar na inicialização (um por linha).
# Exemplo:
# traceroute
# nmap
EOF
                chown "$USER_ID:$GROUP_ID" "$APT_STATE_FILE" 2>/dev/null || true
            fi

            if [ -s "$APT_STATE_FILE" ]; then
                mapfile -t APT_LIST < <(grep -vE '^\s*(#|$)' "$APT_STATE_FILE" || true)
                echo "[entrypoint] Aplicando pacotes apt persistentes..."
                if [ "${#APT_LIST[@]}" -gt 0 ]; then
                    if [ "$EUID" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
                        echo "[entrypoint] sudo não disponível; ignorando restauração apt. Instale sudo ou execute como root." >&2
                    else
                        pkg_apt apply || echo "[entrypoint] Falha ao aplicar pacotes apt" >&2
                    fi
                else
                    echo "[entrypoint] Nenhum pacote listado para restaurar via apt."
                fi
            fi
        else
            echo "[entrypoint] Aviso: estado de pacotes não inicializado (ver permissões do volume)." >&2
        fi
    else
        echo "[entrypoint] Restauração automática de pacotes desativada (PKG_AUTO_RESTORE=0)." >&2
    fi
fi

# A partir daqui, exporta variável para pkg_add/pkg_apt usarem o caminho final do state
export PKG_STATE
export APT_STATE_FILE
export PKG_AUTO_LIST

# Loader de sugestão: cria command_not_found_handle com recomendação de pacote.
create_lazy_loader() {
    if [ "$PKG_LAZY_INSTALL" = "0" ]; then
        return
    fi

    cat > "$LAZY_LOADER_FILE" <<'EOF'
command_not_found_handle() {
    local cmd="$1"
    if [ "${PKG_LAZY_INSTALL:-1}" = "1" ] && command -v pkg_add >/dev/null 2>&1; then
        if pkg_add suggest --raw "$cmd" >/dev/null 2>&1; then
            pkg_add suggest "$cmd"
            return 127
        fi
    fi

    printf "bash: %s: command not found\n" "$cmd" >&2
    return 127
}
EOF

    # Garante que o handler seja carregado em shells interativos
    local bashrc="$HOME/.bashrc"
    if ! grep -Fq ".pkg_add_lazy.sh" "$bashrc" 2>/dev/null; then
        echo '[ -f "$HOME/.pkg_add_lazy.sh" ] && source "$HOME/.pkg_add_lazy.sh"' >> "$bashrc"
    fi
}

create_lazy_loader

start_tools_web_if_enabled() {
    if [ "$TOOLS_WEB_AUTOSTART" = "0" ]; then
        return
    fi

    if ! command -v tools-web >/dev/null 2>&1; then
        return
    fi

    if [ ! -d "/backup" ]; then
        echo "[entrypoint] /backup não encontrado; tools-web não iniciado." >&2
        return
    fi

    if pgrep -f "[/]usr/local/bin/tools-web" >/dev/null 2>&1 || pgrep -f "[/]usr/local/bin/backup-web" >/dev/null 2>&1; then
        return
    fi

    local log_path="$TOOLS_WEB_LOG"
    if ! touch "$log_path" 2>/dev/null; then
        log_path="/tools/.tools-web.log"
        touch "$log_path" 2>/dev/null || true
    fi

    echo "[entrypoint] Iniciando tools-web em background (log: $log_path)" >&2
    nohup /usr/local/bin/tools-web >> "$log_path" 2>&1 &
}

# Se houver argumentos, execute-os como um comando
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    start_tools_web_if_enabled
    exec bash
fi
