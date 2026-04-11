#!/usr/bin/env bash

DEVOPS_CLIENT_COMPLETION_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

_devops_client_find_bin() {
  local client_bin=""

  client_bin="$(type -P client 2>/dev/null || true)"
  if [ -n "$client_bin" ]; then
    printf '%s\n' "$client_bin"
    return 0
  fi

  if [ -x /tools/bin/client ]; then
    printf '%s\n' /tools/bin/client
    return 0
  fi

  if [ -x "${DEVOPS_CLIENT_COMPLETION_ROOT}/bin/client" ]; then
    printf '%s\n' "${DEVOPS_CLIENT_COMPLETION_ROOT}/bin/client"
    return 0
  fi

  if [ -x /usr/local/bin/client ]; then
    printf '%s\n' /usr/local/bin/client
    return 0
  fi

  return 1
}

_devops_client_list_names() {
  local client_bin=""
  client_bin="$(_devops_client_find_bin)" || return 0
  "$client_bin" list 2>/dev/null | sed 's/^[*[:space:]]*//'
}

_devops_client_list_templates() {
  local client_bin=""
  client_bin="$(_devops_client_find_bin)" || return 0
  "$client_bin" template list 2>/dev/null | awk '{print $1}'
}

_devops_client_complete() {
  local cur prev words cword

  if declare -F _init_completion >/dev/null 2>&1; then
    _init_completion -n : || return
  else
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD
  fi

  local commands="list init delete rename clone template current activate deactivate show help use enter clear"
  local template_subcommands="list show"

  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
    return 0
  fi

  case "${words[1]}" in
    use|enter|activate|delete|show)
      COMPREPLY=( $(compgen -W "$(_devops_client_list_names)" -- "$cur") )
      return 0
      ;;
    clear|deactivate|current|help|list)
      return 0
      ;;
    init)
      if [ "$prev" = "--template" ]; then
        COMPREPLY=( $(compgen -W "$(_devops_client_list_templates)" -- "$cur") )
        return 0
      fi
      if printf '%s\n' "${words[@]}" | grep -qx -- '--template'; then
        return 0
      fi
      COMPREPLY=( $(compgen -W "--template" -- "$cur") )
      return 0
      ;;
    rename|clone)
      if [ "$cword" -eq 2 ]; then
        COMPREPLY=( $(compgen -W "$(_devops_client_list_names)" -- "$cur") )
      fi
      return 0
      ;;
    template)
      if [ "$cword" -eq 2 ]; then
        COMPREPLY=( $(compgen -W "$template_subcommands" -- "$cur") )
        return 0
      fi
      if [ "${words[2]:-}" = "show" ] && [ "$cword" -eq 3 ]; then
        COMPREPLY=( $(compgen -W "$(_devops_client_list_templates)" -- "$cur") )
      fi
      return 0
      ;;
  esac
}

complete -F _devops_client_complete client
