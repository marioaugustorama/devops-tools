#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE=${VERSION_FILE:-version}

usage() {
  echo "Uso: $0 <show|bump {major|minor|patch}> [--stage]" >&2
}

stage=false
if [[ ${1-} == "" ]]; then
  usage; exit 1
fi

cmd=$1; shift || true
if [[ ${1-} == "--stage" ]]; then
  stage=true; shift || true
fi

read_version() {
  if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Arquivo $VERSION_FILE não encontrado" >&2
    exit 1
  fi
  cat "$VERSION_FILE" | tr -d '\n' | sed 's/^\s*//;s/\s*$//'
}

write_version() {
  local new=$1
  echo "$new" > "$VERSION_FILE"
  if $stage && command -v git >/dev/null 2>&1; then
    git add "$VERSION_FILE" || true
  fi
}

normalize() {
  # entra: v1.2.3 ou 1.2.3 -> sai: prefix("v"|"") major minor patch
  local v="$1"
  local prefix=""
  if [[ $v == v* ]]; then
    prefix="v"
    v=${v#v}
  fi
  IFS='.' read -r major minor patch <<< "$v"
  if [[ -z ${major-} || -z ${minor-} || -z ${patch-} ]]; then
    echo "Versão inválida: $1 (esperado: vMAJOR.MINOR.PATCH)" >&2
    exit 1
  fi
  echo "$prefix" "$major" "$minor" "$patch"
}

case "$cmd" in
  show)
    read_version
    ;;
  bump)
    kind=${1-}
    if [[ -z ${kind} ]]; then usage; exit 1; fi
    cur=$(read_version)
    read -r prefix major minor patch < <(normalize "$cur")
    case "$kind" in
      major)
        major=$((major+1)); minor=0; patch=0 ;;
      minor)
        minor=$((minor+1)); patch=0 ;;
      patch)
        patch=$((patch+1)) ;;
      *) echo "Tipo inválido: $kind (major|minor|patch)" >&2; exit 1 ;;
    esac
    new="$prefix$major.$minor.$patch"
    write_version "$new"
    echo "$cur -> $new"
    ;;
  *)
    usage; exit 1 ;;
esac

