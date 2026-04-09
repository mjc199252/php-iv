#!/usr/bin/env zsh

emulate -L zsh

_php_iv_bootstrap_dir() {
  local source_path="${(%):-%N}"
  cd "$(dirname "$source_path")" >/dev/null 2>&1 && pwd
}

export PHP_IV_PATH="${PHP_IV_PATH:-$(_php_iv_bootstrap_dir)}"

function php-iv {
  local core="${PHP_IV_PATH}/bin/php-iv-core"

  if [[ ! -x "$core" ]]; then
    printf 'php-iv bootstrap is broken: missing executable core at %s\n' "$core" >&2
    return 1
  fi

  case "${1:-}" in
    select)
      if (( $# < 2 )); then
        "$core" "$@"
        return $?
      fi

      "$core" select --shell-managed "$2" || return $?

      local env_output
      env_output="$("$core" env "$2")" || return $?
      eval "$env_output"
      rehash 2>/dev/null || true
      ;;
    *)
      "$core" "$@"
      ;;
  esac
}
