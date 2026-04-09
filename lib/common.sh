#!/usr/bin/env bash

PHP_IV_TOOL_VERSION="1.0.0"

PHP_IV_EXIT_USAGE=2
PHP_IV_EXIT_DEPENDENCY=10
PHP_IV_EXIT_VERSION_UNSUPPORTED=20
PHP_IV_EXIT_EXTENSION_UNSUPPORTED=21
PHP_IV_EXIT_BUILD_FAILED=30

php_iv_log() {
  local level="$1"
  shift

  local threshold="${PHP_IV_LOG_LEVEL:-info}"
  local threshold_rank=1
  local level_rank=1

  case "$threshold" in
    debug) threshold_rank=0 ;;
    info) threshold_rank=1 ;;
    warn) threshold_rank=2 ;;
    error) threshold_rank=3 ;;
  esac

  case "$level" in
    debug) level_rank=0 ;;
    info) level_rank=1 ;;
    warn) level_rank=2 ;;
    error) level_rank=3 ;;
  esac

  if (( level_rank < threshold_rank )); then
    return 0
  fi

  printf '[%s] %s\n' "$level" "$*" >&2
}

php_iv_init_layout() {
  export PHP_IV_ROOT="${PHP_IV_ROOT:-$HOME/.php-iv}"
  export PHP_IV_CACHE_DIR="${PHP_IV_CACHE_DIR:-$PHP_IV_ROOT/cache}"
  export PHP_IV_MAKE_JOBS="${PHP_IV_MAKE_JOBS:-$(php_iv_default_make_jobs)}"
  export PHP_IV_LOG_LEVEL="${PHP_IV_LOG_LEVEL:-info}"

  export PHP_IV_VERSIONS_DIR="$PHP_IV_ROOT/versions"
  export PHP_IV_ETC_DIR="$PHP_IV_ROOT/etc"
  export PHP_IV_LOG_DIR="$PHP_IV_ROOT/logs"
  export PHP_IV_TMP_DIR="$PHP_IV_ROOT/tmp"
  export PHP_IV_SRC_DIR="$PHP_IV_ROOT/src"
  export PHP_IV_CURRENT_LINK="$PHP_IV_ROOT/current"

  mkdir -p \
    "$PHP_IV_ROOT" \
    "$PHP_IV_CACHE_DIR" \
    "$PHP_IV_VERSIONS_DIR" \
    "$PHP_IV_ETC_DIR" \
    "$PHP_IV_LOG_DIR" \
    "$PHP_IV_TMP_DIR" \
    "$PHP_IV_SRC_DIR"
}

php_iv_default_make_jobs() {
  local jobs="4"

  if command -v getconf >/dev/null 2>&1; then
    jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '4')"
  elif command -v sysctl >/dev/null 2>&1; then
    jobs="$(sysctl -n hw.ncpu 2>/dev/null || printf '4')"
  fi

  if [[ -z "$jobs" || "$jobs" == "0" ]]; then
    jobs="4"
  fi

  printf '%s\n' "$jobs"
}

php_iv_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

php_iv_realpath_dir() {
  local target="$1"
  if [[ -d "$target" ]]; then
    (cd "$target" >/dev/null 2>&1 && pwd -P)
  else
    return 1
  fi
}

php_iv_realpath_parent() {
  local target="$1"
  local parent
  parent="$(dirname "$target")"
  (cd "$parent" >/dev/null 2>&1 && printf '%s/%s\n' "$(pwd -P)" "$(basename "$target")")
}

php_iv_version_to_key() {
  local version="$1"
  local major="0"
  local minor="0"
  local patch="0"

  IFS='.' read -r major minor patch <<<"$version"
  printf '%05d.%05d.%05d\n' "${major:-0}" "${minor:-0}" "${patch:-0}"
}

php_iv_version_compare() {
  local left="$1"
  local right="$2"
  local left_key right_key

  left_key="$(php_iv_version_to_key "$left")"
  right_key="$(php_iv_version_to_key "$right")"

  if [[ "$left_key" == "$right_key" ]]; then
    printf '0\n'
  elif [[ "$left_key" > "$right_key" ]]; then
    printf '1\n'
  else
    printf -- '-1\n'
  fi
}

php_iv_version_ge() {
  [[ "$(php_iv_version_compare "$1" "$2")" != "-1" ]]
}

php_iv_version_le() {
  [[ "$(php_iv_version_compare "$1" "$2")" != "1" ]]
}

php_iv_version_in_range() {
  local version="$1"
  local min_version="$2"
  local max_version="$3"

  php_iv_version_ge "$version" "$min_version" && php_iv_version_le "$version" "$max_version"
}

php_iv_normalize_version_spec() {
  local spec="${1:-}"

  spec="$(printf '%s' "$spec" | tr '[:upper:]' '[:lower:]')"
  spec="${spec#php}"
  spec="${spec#v}"
  spec="${spec//_/\.}"
  spec="${spec// /}"

  if [[ "$spec" =~ ^[0-9]{2}$ ]]; then
    printf '%s.%s\n' "${spec:0:1}" "${spec:1:1}"
    return 0
  fi

  if [[ "$spec" =~ ^[0-9]{3}$ ]]; then
    printf '%s.%s.%s\n' "${spec:0:1}" "${spec:1:1}" "${spec:2:1}"
    return 0
  fi

  printf '%s\n' "$spec"
}

php_iv_fetcher() {
  if php_iv_command_exists curl; then
    printf 'curl\n'
    return 0
  fi

  if php_iv_command_exists wget; then
    printf 'wget\n'
    return 0
  fi

  return 1
}

php_iv_fetch_file() {
  local url="$1"
  local destination="$2"
  local fetcher

  fetcher="$(php_iv_fetcher)" || return "$PHP_IV_EXIT_DEPENDENCY"

  mkdir -p "$(dirname "$destination")"

  case "$fetcher" in
    curl)
      curl --fail --location --retry 3 --output "$destination" "$url"
      ;;
    wget)
      wget -O "$destination" "$url"
      ;;
  esac
}

php_iv_sha256_cmd() {
  if php_iv_command_exists sha256sum; then
    printf 'sha256sum\n'
    return 0
  fi

  if php_iv_command_exists shasum; then
    printf 'shasum\n'
    return 0
  fi

  return 1
}

php_iv_verify_sha256() {
  local file_path="$1"
  local expected="$2"
  local sha_cmd actual

  if [[ -z "$expected" ]]; then
    return 0
  fi

  sha_cmd="$(php_iv_sha256_cmd)" || return 1

  case "$sha_cmd" in
    sha256sum)
      actual="$(sha256sum "$file_path" | awk '{print $1}')"
      ;;
    shasum)
      actual="$(shasum -a 256 "$file_path" | awk '{print $1}')"
      ;;
  esac

  [[ "$actual" == "$expected" ]]
}

php_iv_make_temp_dir() {
  local prefix="$1"
  mktemp -d "$PHP_IV_TMP_DIR/${prefix}.XXXXXX"
}

php_iv_cleanup_dir() {
  local target="${1:-}"
  if [[ -n "$target" && -d "$target" ]]; then
    rm -rf "$target"
  fi
}

php_iv_extract_archive() {
  local archive="$1"
  local destination="$2"

  mkdir -p "$destination"
  tar -xf "$archive" -C "$destination"
}

php_iv_shell_escape() {
  printf '%q' "$1"
}

php_iv_write_metadata() {
  local install_dir="$1"
  local conf_dir="$2"

  cat >"$install_dir/.php-iv-meta" <<EOF
PHP_IV_INSTALLED_VERSION="$PHP_IV_VERSION"
PHP_IV_INSTALLED_SERIES="$PHP_IV_SERIES"
PHP_IV_INSTALLED_TIER="$PHP_IV_SUPPORT_TIER"
PHP_IV_INSTALLED_CONF_DIR="$conf_dir"
EOF
}
