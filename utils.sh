#!/bin/bash
set -euo pipefail

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

# Função para obter a última versão de um repositório GitHub
get_latest_version() {
    local repo=$1
    local release_url="https://api.github.com/repos/${repo}/releases/latest"

    local latest_version
    latest_version=$(curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 "$release_url" | grep -oP '"tag_name":\s*"\K[^\"]+')

    if [ -z "${latest_version:-}" ]; then
        error_exit "Não foi possível determinar a última versão de ${repo}."
    fi

    echo "$latest_version"
}

# Diretório de cache para artefatos de pacotes (persistente via /var/lib/devops-pkg)
get_pkg_cache_dir() {
    local cache_dir="${PKG_CACHE_DIR:-/var/lib/devops-pkg/cache}"
    if mkdir -p "$cache_dir" 2>/dev/null; then
        echo "$cache_dir"
        return 0
    fi

    local fallback="${HOME:-/tmp}/.devops-pkg/cache"
    mkdir -p "$fallback" 2>/dev/null || true
    echo "$fallback"
}

# Diretório persistente para binários instalados sob demanda.
get_pkg_bin_dir() {
    local bin_dir="${PKG_BIN_DIR:-}"
    if [ -n "$bin_dir" ] && mkdir -p "$bin_dir" 2>/dev/null && [ -w "$bin_dir" ]; then
        echo "$bin_dir"
        return 0
    fi

    local fallback="${HOME:-/tmp}/.devops-pkg/bin"
    if mkdir -p "$fallback" 2>/dev/null && [ -w "$fallback" ]; then
        echo "$fallback"
        return 0
    fi

    echo "/usr/local/bin"
}

pkg_bin_path() {
    local name="${1:-}"
    [ -n "$name" ] || error_exit "pkg_bin_path requer o nome do binário"
    printf '%s/%s\n' "$(get_pkg_bin_dir)" "$name"
}

install_pkg_bin() {
    local source_path="${1:-}"
    local dest_name="${2:-}"
    [ -n "$source_path" ] || error_exit "install_pkg_bin requer o caminho de origem"
    [ -n "$dest_name" ] || dest_name="$(basename "$source_path")"

    install -o root -g root -m 0755 "$source_path" "$(pkg_bin_path "$dest_name")" || \
        error_exit "Falha ao instalar o binário persistente: $dest_name"
}

link_pkg_bin() {
    local target_name="${1:-}"
    local link_name="${2:-}"
    [ -n "$target_name" ] || error_exit "link_pkg_bin requer o binário alvo"
    [ -n "$link_name" ] || link_name="$target_name"

    ln -sf "$(pkg_bin_path "$target_name")" "$(pkg_bin_path "$link_name")" || \
        error_exit "Falha ao criar link persistente: $link_name -> $target_name"
}

pkg_bin_exists() {
    local name="${1:-}"
    [ -n "$name" ] || error_exit "pkg_bin_exists requer o nome do binário"
    [ -x "$(pkg_bin_path "$name")" ]
}

# Baixa arquivo com cache local persistente:
# - se arquivo já existe no cache, reaproveita sem rede
# - se não existe, baixa e salva no cache para próximas execuções
cache_download() {
    local url="$1"
    local output_path="$2"
    local cache_name="${3:-$(basename "$output_path")}"
    local cache_enabled="${PKG_CACHE_ENABLED:-1}"

    if [ "$cache_enabled" = "0" ]; then
        curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$output_path" "$url" || error_exit "Falha ao baixar arquivo (cache desabilitado): $url"
        return 0
    fi

    local cache_dir cache_path tmp_cache
    cache_dir="$(get_pkg_cache_dir)"
    cache_path="${cache_dir}/${cache_name}"

    if [ -s "$cache_path" ]; then
        echo "Usando cache local: $cache_name"
        cp -f "$cache_path" "$output_path" || error_exit "Falha ao copiar artefato do cache: $cache_name"
        return 0
    fi

    echo "Baixando artefato e salvando em cache: $cache_name"
    tmp_cache="${cache_path}.tmp.$$"
    curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$tmp_cache" "$url" || {
        rm -f "$tmp_cache"
        error_exit "Falha ao baixar arquivo: $url"
    }
    mv -f "$tmp_cache" "$cache_path" || error_exit "Falha ao persistir artefato no cache: $cache_name"
    cp -f "$cache_path" "$output_path" || error_exit "Falha ao copiar artefato baixado para destino: $output_path"
}

# Resolve comando -> pacote a partir de um índice TSV local.
# Formatos de saída:
# - human (padrão): mensagem amigável para terminal
# - raw: imprime somente o pacote
# - tsv: imprime comando<TAB>pacote<TAB>descrição
suggest_package_for_command() {
    local command_name="${1:-}"
    local output_mode="${2:-human}"
    local commands_index="${COMMANDS_INDEX:-/usr/local/scripts/commands.tsv}"
    local map_cmd map_pkg map_desc

    [ -n "$command_name" ] || return 2
    [ -f "$commands_index" ] || return 1

    while IFS=$'\t' read -r map_cmd map_pkg map_desc; do
        [[ -z "${map_cmd:-}" || "${map_cmd:0:1}" == "#" ]] && continue
        [ "$map_cmd" = "$command_name" ] || continue

        map_desc="${map_desc:-Sem descrição}"
        case "$output_mode" in
            raw)
                printf "%s\n" "$map_pkg"
                ;;
            tsv)
                printf "%s\t%s\t%s\n" "$map_cmd" "$map_pkg" "$map_desc"
                ;;
            *)
                cat <<EOF
Comando '$command_name' não encontrado.
Pacote sugerido: $map_pkg
Descrição: $map_desc
Para instalar:
  pkg_add install $map_pkg
EOF
                ;;
        esac
        return 0
    done < "$commands_index"

    return 1
}
