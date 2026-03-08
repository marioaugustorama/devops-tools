#!/bin/bash
set -euo pipefail
shopt -s nullglob

# Diretório onde os scripts estão localizados
SCRIPT_DIR="/usr/local/scripts"
PKG_INDEX="${PKG_INDEX:-$SCRIPT_DIR/packages.tsv}"
RUN_ALL_MODE="${RUN_ALL_MODE:-default}" # default|all
RUN_ALL_GROUPS="${RUN_ALL_GROUPS:-}"    # ex.: "k8s,cloud"

# Arquivo de log
LOG_FILE="/var/log/run_all.log"

declare -A PKG_DEFAULT
declare -A PKG_GROUP

# Função para registrar logs
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

normalize_bool() {
    local value="${1:-}"
    value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
    case "$value" in
        1|true|yes|y|on|sim) echo "1" ;;
        0|false|no|n|off|nao|não) echo "0" ;;
        *) echo "0" ;;
    esac
}

load_package_metadata() {
    if [ ! -f "$PKG_INDEX" ]; then
        return
    fi

    while IFS=$'\t' read -r name _desc group default_install; do
        [[ -z "${name:-}" || "${name:0:1}" == "#" ]] && continue
        PKG_GROUP["$name"]="${group:-general}"
        PKG_DEFAULT["$name"]="$(normalize_bool "${default_install:-1}")"
    done < "$PKG_INDEX"
}

is_group_selected() {
    local pkg_group="$1"
    [ -z "$RUN_ALL_GROUPS" ] && return 0

    IFS=',' read -r -a selected <<< "$RUN_ALL_GROUPS"
    for group in "${selected[@]}"; do
        group="$(echo "$group" | xargs)"
        [ -z "$group" ] && continue
        [ "$group" = "$pkg_group" ] && return 0
    done
    return 1
}

# Início do script
log_message "Iniciando a execução dos scripts em $SCRIPT_DIR"
log_message "Modo de instalação: RUN_ALL_MODE=$RUN_ALL_MODE RUN_ALL_GROUPS=${RUN_ALL_GROUPS:-<vazio>}"
load_package_metadata

# Itera sobre todos os scripts .sh no diretório especificado
for script in "$SCRIPT_DIR"/*.sh; do
    base="$(basename "$script")"
    pkg="${base%.sh}"

    # Pula utilitários que não são instaladores
    if [[ "$base" == "version.sh" ]]; then
        log_message "Pulando $base (utilitário de versão)."
        continue
    fi

    pkg_group="${PKG_GROUP[$pkg]:-general}"
    pkg_default="${PKG_DEFAULT[$pkg]:-1}"

    if [ "$RUN_ALL_MODE" != "all" ] && [ -n "$RUN_ALL_GROUPS" ]; then
        if ! is_group_selected "$pkg_group"; then
            log_message "Pulando $base (fora dos grupos selecionados: $RUN_ALL_GROUPS)."
            continue
        fi
    elif [ "$RUN_ALL_MODE" != "all" ] && [ "$pkg_default" != "1" ]; then
        log_message "Pulando $base (on-demand: use pkg_add install $pkg)."
        continue
    fi

    if [ -x "$script" ]; then
        log_message "Executando o script: $script"
        "$script"
        log_message "Script $script executado com sucesso."
    else
        log_message "O arquivo $script não é executável ou não existe."
    fi
done

# Fim do script
log_message "Execução dos scripts concluída."
