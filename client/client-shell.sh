#!/usr/bin/env bash

DEVOPS_CLIENT_SHELL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -n "${DEVOPS_CLIENT_SHELL_LOADED:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
export DEVOPS_CLIENT_SHELL_LOADED=1

devops_client_command() {
  local client_bin=""

  client_bin="$(type -P client 2>/dev/null || true)"
  if [ -n "$client_bin" ]; then
    "$client_bin" "$@"
    return
  fi

  if [ -x /tools/bin/client ]; then
    /tools/bin/client "$@"
    return
  fi

  if [ -x "${DEVOPS_CLIENT_SHELL_ROOT}/bin/client" ]; then
    "${DEVOPS_CLIENT_SHELL_ROOT}/bin/client" "$@"
    return
  fi

  if [ -x /usr/local/bin/client ]; then
    /usr/local/bin/client "$@"
    return
  fi

  echo "Comando 'client' não encontrado." >&2
  return 127
}

devops_client_refresh_prompt() {
  local base_ps1="${DEVOPS_CLIENT_BASE_PS1:-$PS1}"
  if [ -n "${DEVOPS_CLIENT_NAME:-}" ]; then
    PS1="[client:${DEVOPS_CLIENT_NAME}] ${base_ps1}"
  else
    PS1="${base_ps1}"
  fi
}

devops_client_apply_support_files() {
  if [ -n "${DEVOPS_CLIENT_ENV_FILE:-}" ] && [ -f "${DEVOPS_CLIENT_ENV_FILE}" ]; then
    # shellcheck disable=SC1090
    source "${DEVOPS_CLIENT_ENV_FILE}"
  fi

  if [ -n "${DEVOPS_CLIENT_ALIASES_FILE:-}" ] && [ -f "${DEVOPS_CLIENT_ALIASES_FILE}" ]; then
    # shellcheck disable=SC1090
    source "${DEVOPS_CLIENT_ALIASES_FILE}"
  fi

  if [ -n "${DEVOPS_CLIENT_BIN:-}" ] && [ -d "${DEVOPS_CLIENT_BIN}" ]; then
    case ":${PATH}:" in
      *":${DEVOPS_CLIENT_BIN}:"*) ;;
      *) export PATH="${DEVOPS_CLIENT_BIN}:${PATH}" ;;
    esac
  fi
}

devops_client_bootstrap_current() {
  local current
  current="$(devops_client_command current 2>/dev/null || true)"
  if [ -n "$current" ]; then
    eval "$(devops_client_command activate "$current")"
    devops_client_apply_support_files
  fi
}

client() {
  local subcommand="${1:-help}"
  shift || true

  case "$subcommand" in
    use|activate)
      local name="${1:-}"
      [ -n "$name" ] || {
        echo "Uso: client use <cliente>" >&2
        return 1
      }
      eval "$(devops_client_command activate "$name")"
      devops_client_apply_support_files
      devops_client_refresh_prompt
      ;;
    clear|deactivate)
      eval "$(devops_client_command deactivate)"
      devops_client_refresh_prompt
      ;;
    enter)
      local name="${1:-}"
      [ -n "$name" ] || {
        echo "Uso: client enter <cliente>" >&2
        return 1
      }
      eval "$(devops_client_command activate "$name")"
      devops_client_apply_support_files
      devops_client_refresh_prompt
      bash -l
      ;;
    *)
      devops_client_command "$subcommand" "$@"
      ;;
  esac
}

ssh() {
  if [ -n "${DEVOPS_CLIENT_SSH_CONFIG:-}" ] && [ -f "${DEVOPS_CLIENT_SSH_CONFIG}" ]; then
    command ssh -F "${DEVOPS_CLIENT_SSH_CONFIG}" "$@"
    return
  fi

  command ssh "$@"
}

scp() {
  if [ -n "${DEVOPS_CLIENT_SSH_CONFIG:-}" ] && [ -f "${DEVOPS_CLIENT_SSH_CONFIG}" ]; then
    command scp -F "${DEVOPS_CLIENT_SSH_CONFIG}" "$@"
    return
  fi

  command scp "$@"
}

if [ -z "${DEVOPS_CLIENT_BASE_PS1:-}" ]; then
  export DEVOPS_CLIENT_BASE_PS1="$PS1"
fi

case ";${PROMPT_COMMAND:-};" in
  *";devops_client_refresh_prompt;"*) ;;
  *)
    if [ -n "${PROMPT_COMMAND:-}" ]; then
      PROMPT_COMMAND="devops_client_refresh_prompt;${PROMPT_COMMAND}"
    else
      PROMPT_COMMAND="devops_client_refresh_prompt"
    fi
    export PROMPT_COMMAND
    ;;
esac

devops_client_bootstrap_current
devops_client_refresh_prompt
