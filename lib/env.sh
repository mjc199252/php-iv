#!/usr/bin/env bash

php_iv_emit_env_for_record() {
  local version="$1"
  local install_dir="$2"
  local conf_dir="$PHP_IV_ETC_DIR/$version"
  local bin_dir="$install_dir/bin"
  local sbin_dir="$install_dir/sbin"
  local man_dir="$install_dir/share/man"

  printf 'export PHP_IV_ACTIVE_VERSION=%q\n' "$version"
  printf 'export PHP_IV_ROOT=%q\n' "$PHP_IV_ROOT"
  printf 'export PHPRC=%q\n' "$conf_dir/php.ini"
  printf 'export PHP_INI_SCAN_DIR=%q\n' "$conf_dir/conf.d"

  if [[ -d "$sbin_dir" ]]; then
    printf 'export PATH=%q:${PATH}\n' "$bin_dir:$sbin_dir"
  else
    printf 'export PATH=%q:${PATH}\n' "$bin_dir"
  fi

  if [[ -d "$man_dir" ]]; then
    printf 'export MANPATH=%q:${MANPATH:-}\n' "$man_dir"
  fi
}

php_iv_emit_env() {
  local spec="${1:-}"
  local record version series install_dir

  if [[ -z "$spec" ]]; then
    install_dir="$(php_iv_current_install_dir || true)"
    if [[ -z "$install_dir" ]]; then
      php_iv_log error "No PHP version is currently selected."
      return "$PHP_IV_EXIT_VERSION_UNSUPPORTED"
    fi

    php_iv_load_install_metadata "$install_dir" || {
      php_iv_log error "Unable to read metadata for current PHP at $install_dir"
      return "$PHP_IV_EXIT_BUILD_FAILED"
    }
    php_iv_emit_env_for_record "$PHP_IV_INSTALLED_VERSION" "$install_dir"
    return 0
  fi

  record="$(php_iv_resolve_installed_record "$spec")" || {
    php_iv_log error "PHP version $spec is not installed."
    return "$PHP_IV_EXIT_VERSION_UNSUPPORTED"
  }

  IFS='|' read -r version series install_dir <<<"$record"
  php_iv_emit_env_for_record "$version" "$install_dir"
}
