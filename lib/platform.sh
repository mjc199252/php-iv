#!/usr/bin/env bash

php_iv_detect_platform() {
  local uname_s uname_m

  uname_s="$(uname -s 2>/dev/null || printf 'unknown')"
  uname_m="$(uname -m 2>/dev/null || printf 'unknown')"

  case "$uname_s" in
    Darwin) export PHP_IV_HOST_OS="macos" ;;
    Linux) export PHP_IV_HOST_OS="linux" ;;
    *) export PHP_IV_HOST_OS="unknown" ;;
  esac

  case "$uname_m" in
    x86_64|amd64) export PHP_IV_HOST_ARCH="x86_64" ;;
    arm64|aarch64) export PHP_IV_HOST_ARCH="arm64" ;;
    *) export PHP_IV_HOST_ARCH="$uname_m" ;;
  esac

  export PHP_IV_HOST_PLATFORM="${PHP_IV_HOST_OS}-${PHP_IV_HOST_ARCH}"
}

php_iv_platform_supported() {
  local supported="$1"
  local token

  for token in $supported; do
    if [[ "$token" == "$PHP_IV_HOST_PLATFORM" ]]; then
      return 0
    fi
  done

  return 1
}

php_iv_brew_prefix() {
  local formula="$1"

  if [[ "$PHP_IV_HOST_OS" != "macos" ]]; then
    return 1
  fi

  if ! php_iv_command_exists brew; then
    return 1
  fi

  brew --prefix "$formula" 2>/dev/null
}

php_iv_build_path_entries() {
  local entries=()
  local prefix
  local formula

  if [[ "$PHP_IV_HOST_OS" == "macos" ]]; then
    for formula in autoconf bison re2c pkgconf pkg-config; do
      prefix="$(php_iv_brew_prefix "$formula" || true)"
      if [[ -n "$prefix" && -d "$prefix/bin" ]]; then
        entries+=("$prefix/bin")
      fi
    done
  fi

  printf '%s\n' "${entries[@]}"
}

php_iv_pkg_config_entries() {
  local entries=()
  local prefix
  local formula

  if [[ "$PHP_IV_HOST_OS" == "macos" ]]; then
    for formula in openssl@3 curl libxml2 sqlite zlib bzip2 libzip oniguruma; do
      prefix="$(php_iv_brew_prefix "$formula" || true)"
      if [[ -n "$prefix" && -d "$prefix/lib/pkgconfig" ]]; then
        entries+=("$prefix/lib/pkgconfig")
      fi
      if [[ -n "$prefix" && -d "$prefix/share/pkgconfig" ]]; then
        entries+=("$prefix/share/pkgconfig")
      fi
    done
  fi

  printf '%s\n' "${entries[@]}"
}

php_iv_prepare_build_environment() {
  local entries=()
  local pkg_entries=()
  local line

  while IFS= read -r line; do
    [[ -n "$line" ]] && entries+=("$line")
  done < <(php_iv_build_path_entries)

  while IFS= read -r line; do
    [[ -n "$line" ]] && pkg_entries+=("$line")
  done < <(php_iv_pkg_config_entries)

  if [[ ${#entries[@]} -gt 0 ]]; then
    export PATH="$(IFS=:; printf '%s' "${entries[*]}"):$PATH"
  fi

  if [[ ${#pkg_entries[@]} -gt 0 ]]; then
    if [[ -n "${PKG_CONFIG_PATH:-}" ]]; then
      export PKG_CONFIG_PATH="$(IFS=:; printf '%s' "${pkg_entries[*]}"):$PKG_CONFIG_PATH"
    else
      export PKG_CONFIG_PATH="$(IFS=:; printf '%s' "${pkg_entries[*]}")"
    fi
  fi
}
