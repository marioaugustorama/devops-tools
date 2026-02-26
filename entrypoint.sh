#!/bin/bash

set -euo pipefail

# Define o UID e GID do usuário corrente
USER_ID=$(id -u)
GROUP_ID=$(id -g)
PKG_STATE="/var/lib/devops-pkg/installed.list"
APT_STATE_FILE="/var/lib/devops-pkg/apt-packages.list"
PKG_AUTO_LIST="${PKG_AUTO_LIST:-/var/lib/devops-pkg/auto-install.list}"
PKG_INDEX="${PKG_INDEX:-/usr/local/scripts/packages.tsv}"
PKG_AUTO_RESTORE="${PKG_AUTO_RESTORE:-0}"
PKG_LAZY_INSTALL="${PKG_LAZY_INSTALL:-1}"
LAZY_LOADER_FILE="/tools/.pkg_add_lazy.sh"
BACKUP_WEB_AUTOSTART="${BACKUP_WEB_AUTOSTART:-1}"
BACKUP_WEB_LOG="${BACKUP_WEB_LOG:-/var/log/backup-web.log}"

# Função para garantir que o arquivo de estado exista e seja gravável,
# com fallback para $HOME se o volume estiver somente leitura ou com owner incorreto.
ensure_state_file() {
    local target="$1"
    local fallback="$2"
    local dir
    dir=$(dirname "$target")
    mkdir -p "$dir" 2>/dev/null || true
    if touch "$target" 2>/dev/null; then
        chown "$USER_ID:$GROUP_ID" "$target" 2>/dev/null || true
        echo "$target"
        return
    fi

    dir=$(dirname "$fallback")
    mkdir -p "$dir" 2>/dev/null || true
    if touch "$fallback" 2>/dev/null; then
        chown "$USER_ID:$GROUP_ID" "$fallback" 2>/dev/null || true
        echo "$fallback"
        return
    fi

    echo "[entrypoint] Aviso: não foi possível criar arquivo de estado em $target nem em $fallback" >&2
    echo ""
}

# Cria o diretório home se não existir e define as permissões corretas
if [ ! -d "/tools" ]; then
    mkdir -p /tools
    # Quando o container já roda como devops, o chown pode falhar; ignore nesse caso
    chown "$USER_ID:$GROUP_ID" /tools 2>/dev/null || true
fi

# Garante permissões de estado persistente
STATE_DIR="/var/lib/devops-pkg"
mkdir -p "$STATE_DIR"
chown "$USER_ID:$GROUP_ID" "$STATE_DIR" 2>/dev/null || true
chmod 700 "$STATE_DIR" 2>/dev/null || true

# Garante que os arquivos de estado existem e têm permissão de escrita (com fallback)
PKG_STATE=$(ensure_state_file "$PKG_STATE" "/tools/.devops-pkg/installed.list")
APT_STATE_FILE=$(ensure_state_file "$APT_STATE_FILE" "/tools/.devops-pkg/apt-packages.list")
PKG_AUTO_LIST=$(ensure_state_file "$PKG_AUTO_LIST" "/tools/.devops-pkg/auto-install.list")

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

                mapfile -t PKG_LIST < <(grep -vE '^\s*(#|$)' "$PKG_AUTO_LIST" || true)
                echo "[entrypoint] Restaurando pacotes via pkg_add (arquivo: $PKG_AUTO_LIST)..."
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

# Loader sob demanda: cria handler command_not_found para instalar via pkg_add quando houver pacote com mesmo nome
create_lazy_loader() {
    if [ "$PKG_LAZY_INSTALL" = "0" ]; then
        return
    fi

    cat > "$LAZY_LOADER_FILE" <<'EOF'
command_not_found_handle() {
    local cmd="$1"
    shift
    if [ "${PKG_LAZY_INSTALL:-1}" = "0" ]; then
        printf "bash: %s: command not found\n" "$cmd" >&2
        return 127
    fi

    if ! pkg_add info "$cmd" >/dev/null 2>&1; then
        printf "bash: %s: command not found (pacote não encontrado)\n" "$cmd" >&2
        return 127
    fi

    echo "[pkg_add] Instalando pacote '$cmd' sob demanda..."
    if pkg_add install "$cmd"; then
        exec "$cmd" "$@"
    else
        echo "[pkg_add] Falha ao instalar '$cmd'" >&2
        return 127
    fi
}
EOF

    # Garante que o handler seja carregado em shells interativos
    local bashrc="$HOME/.bashrc"
    if ! grep -Fq ".pkg_add_lazy.sh" "$bashrc" 2>/dev/null; then
        echo '[ -f "$HOME/.pkg_add_lazy.sh" ] && source "$HOME/.pkg_add_lazy.sh"' >> "$bashrc"
    fi
}

create_lazy_loader

start_backup_web_if_enabled() {
    if [ "$BACKUP_WEB_AUTOSTART" = "0" ]; then
        return
    fi

    if ! command -v backup-web >/dev/null 2>&1; then
        return
    fi

    if [ ! -d "/backup" ]; then
        echo "[entrypoint] /backup não encontrado; backup-web não iniciado." >&2
        return
    fi

    if pgrep -f "[/]usr/local/bin/backup-web" >/dev/null 2>&1; then
        return
    fi

    local log_path="$BACKUP_WEB_LOG"
    if ! touch "$log_path" 2>/dev/null; then
        log_path="/tools/.backup-web.log"
        touch "$log_path" 2>/dev/null || true
    fi

    echo "[entrypoint] Iniciando backup-web em background (log: $log_path)" >&2
    nohup /usr/local/bin/backup-web >> "$log_path" 2>&1 &
}

# Se houver argumentos, execute-os como um comando
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    start_backup_web_if_enabled
    exec bash
fi
