#!/usr/bin/env bash

php_iv_reset_php_manifest() {
  unset PHP_IV_SERIES PHP_IV_VERSION PHP_IV_SOURCE_ARCHIVE PHP_IV_SOURCE_URL PHP_IV_SOURCE_SHA256
  unset PHP_IV_SUPPORT_TIER PHP_IV_INSTALLABLE PHP_IV_SUPPORTED_PLATFORMS PHP_IV_NOTES PHP_IV_SOURCE_DIR
  unset PHP_IV_EXPERIMENTAL_PLATFORMS PHP_IV_OPENSSL_COMPONENT PHP_IV_APPEND_CFLAGS PHP_IV_APPEND_CPPFLAGS PHP_IV_APPEND_LDFLAGS
  PHP_IV_CONFIGURE_ARGS=()
  PHP_IV_TOOLCHAIN_TOOLS=()
  PHP_IV_TOOLCHAIN_COMPONENTS=()
}

php_iv_load_php_manifest() {
  local manifest_file="$1"
  php_iv_reset_php_manifest
  # shellcheck source=/dev/null
  source "$manifest_file"
}

php_iv_available_php_manifest_files() {
  local manifest
  for manifest in "$PHP_IV_PATH"/manifests/php/*.sh; do
    [[ -f "$manifest" ]] && printf '%s\n' "$manifest"
  done
}

php_iv_available_ext_manifest_files() {
  local manifest
  for manifest in "$PHP_IV_PATH"/manifests/ext/*.sh; do
    [[ -f "$manifest" ]] && printf '%s\n' "$manifest"
  done
}

php_iv_resolve_available_manifest() {
  local spec="$1"
  local normalized
  local best_file=""
  local best_key=""
  local manifest

  normalized="$(php_iv_normalize_version_spec "$spec")"

  if [[ -f "$PHP_IV_PATH/manifests/php/$normalized.sh" ]]; then
    printf '%s\n' "$PHP_IV_PATH/manifests/php/$normalized.sh"
    return 0
  fi

  while IFS= read -r manifest; do
    php_iv_load_php_manifest "$manifest"

    if [[ "$normalized" == "$PHP_IV_VERSION" || "$normalized" == "$PHP_IV_SERIES" ]]; then
      printf '%s\n' "$manifest"
      return 0
    fi

    if [[ "$normalized" =~ ^[0-9]+$ ]]; then
      if [[ "${PHP_IV_SERIES%%.*}" == "$normalized" ]]; then
        if [[ -z "$best_key" || "$(php_iv_version_compare "$PHP_IV_VERSION" "$best_key")" == "1" ]]; then
          best_file="$manifest"
          best_key="$PHP_IV_VERSION"
        fi
      fi
    fi
  done < <(php_iv_available_php_manifest_files)

  if [[ -n "$best_file" ]]; then
    printf '%s\n' "$best_file"
    return 0
  fi

  return 1
}

php_iv_load_install_metadata() {
  local install_dir="$1"

  unset PHP_IV_INSTALLED_VERSION PHP_IV_INSTALLED_SERIES PHP_IV_INSTALLED_TIER PHP_IV_INSTALLED_CONF_DIR

  if [[ -f "$install_dir/.php-iv-meta" ]]; then
    # shellcheck source=/dev/null
    source "$install_dir/.php-iv-meta"
    return 0
  fi

  if [[ -x "$install_dir/bin/php-config" ]]; then
    PHP_IV_INSTALLED_VERSION="$("$install_dir/bin/php-config" --version 2>/dev/null)"
    PHP_IV_INSTALLED_SERIES="${PHP_IV_INSTALLED_VERSION%.*}"
    PHP_IV_INSTALLED_TIER="unknown"
    PHP_IV_INSTALLED_CONF_DIR="$PHP_IV_ETC_DIR/$PHP_IV_INSTALLED_VERSION"
    return 0
  fi

  return 1
}

php_iv_scan_installed_versions() {
  local install_dir
  for install_dir in "$PHP_IV_VERSIONS_DIR"/*; do
    [[ -d "$install_dir" ]] || continue
    if php_iv_load_install_metadata "$install_dir"; then
      printf '%s|%s|%s\n' "$PHP_IV_INSTALLED_VERSION" "$PHP_IV_INSTALLED_SERIES" "$install_dir"
    fi
  done
}

php_iv_resolve_installed_record() {
  local spec="${1:-}"
  local normalized=""
  local best_line=""
  local best_version=""
  local version series install_dir

  if [[ -n "$spec" ]]; then
    normalized="$(php_iv_normalize_version_spec "$spec")"
  fi

  while IFS='|' read -r version series install_dir; do
    if [[ -z "$normalized" ]]; then
      if [[ -n "$best_version" && "$(php_iv_version_compare "$version" "$best_version")" != "1" ]]; then
        continue
      fi
      best_version="$version"
      best_line="$version|$series|$install_dir"
      continue
    fi

    if [[ "$normalized" == "$version" || "$normalized" == "$series" ]]; then
      printf '%s|%s|%s\n' "$version" "$series" "$install_dir"
      return 0
    fi

    if [[ "$normalized" =~ ^[0-9]+$ && "${series%%.*}" == "$normalized" ]]; then
      if [[ -z "$best_version" || "$(php_iv_version_compare "$version" "$best_version")" == "1" ]]; then
        best_version="$version"
        best_line="$version|$series|$install_dir"
      fi
    fi
  done < <(php_iv_scan_installed_versions)

  if [[ -n "$best_line" ]]; then
    printf '%s\n' "$best_line"
    return 0
  fi

  return 1
}

php_iv_current_install_dir() {
  if [[ -L "$PHP_IV_CURRENT_LINK" || -d "$PHP_IV_CURRENT_LINK" ]]; then
    php_iv_realpath_dir "$PHP_IV_CURRENT_LINK"
  fi
}

php_iv_list_available() {
  local manifest

  while IFS= read -r manifest; do
    php_iv_load_php_manifest "$manifest"
    printf '%-5s %-10s %-8s %s\n' "$PHP_IV_SERIES" "$PHP_IV_VERSION" "$PHP_IV_SUPPORT_TIER" "$([[ "$PHP_IV_INSTALLABLE" == "1" ]] && printf 'installable' || printf 'planned')"
  done < <(php_iv_available_php_manifest_files)
}

php_iv_list_installed() {
  local current_dir=""
  local version series install_dir marker

  current_dir="$(php_iv_current_install_dir || true)"

  if ! compgen -G "$PHP_IV_VERSIONS_DIR/*" >/dev/null; then
    printf 'No PHP versions installed under %s\n' "$PHP_IV_VERSIONS_DIR"
    return 0
  fi

  while IFS='|' read -r version series install_dir; do
    marker=" "
    if [[ -n "$current_dir" && "$(php_iv_realpath_dir "$install_dir")" == "$current_dir" ]]; then
      marker="*"
    fi
    printf '%s %-10s %s\n' "$marker" "$version" "$install_dir"
  done < <(php_iv_scan_installed_versions)
}

php_iv_print_manifest_info() {
  local spec="$1"
  local manifest_file

  manifest_file="$(php_iv_resolve_available_manifest "$spec")" || {
    php_iv_log error "Unknown PHP version: $spec"
    return "$PHP_IV_EXIT_VERSION_UNSUPPORTED"
  }

  php_iv_load_php_manifest "$manifest_file"

  printf 'series: %s\n' "$PHP_IV_SERIES"
  printf 'release: %s\n' "$PHP_IV_VERSION"
  printf 'tier: %s\n' "$PHP_IV_SUPPORT_TIER"
  printf 'installable: %s\n' "$PHP_IV_INSTALLABLE"
  printf 'platforms: %s\n' "$PHP_IV_SUPPORTED_PLATFORMS"
  if [[ -n "${PHP_IV_EXPERIMENTAL_PLATFORMS:-}" ]]; then
    printf 'experimental-platforms: %s\n' "$PHP_IV_EXPERIMENTAL_PLATFORMS"
  fi
  printf 'source: %s\n' "$PHP_IV_SOURCE_URL"
  if [[ ${#PHP_IV_TOOLCHAIN_COMPONENTS[@]} -gt 0 ]]; then
    printf 'toolchains: %s\n' "${PHP_IV_TOOLCHAIN_COMPONENTS[*]}"
  fi
  if [[ -n "${PHP_IV_SOURCE_SHA256:-}" ]]; then
    printf 'sha256: %s\n' "$PHP_IV_SOURCE_SHA256"
  fi
  if [[ -n "${PHP_IV_NOTES:-}" ]]; then
    printf 'notes: %s\n' "$PHP_IV_NOTES"
  fi
}

php_iv_reset_ext_manifest() {
  unset PHP_IV_EXT_NAME PHP_IV_EXT_PACKAGE_VERSION PHP_IV_EXT_SOURCE_URL PHP_IV_EXT_SOURCE_ARCHIVE
  unset PHP_IV_EXT_SOURCE_DIR PHP_IV_EXT_SUPPORTED PHP_IV_EXT_REASON PHP_IV_EXT_NOTES
  PHP_IV_EXT_CONFIGURE_ARGS=()
  PHP_IV_EXT_INI_LINES=()
}

php_iv_load_ext_manifest() {
  local manifest_file="$1"
  local php_version="$2"
  local php_series="$3"
  local support_tier="$4"

  php_iv_reset_ext_manifest
  # shellcheck source=/dev/null
  source "$manifest_file"
  php_iv_ext_manifest_load "$php_version" "$php_series" "$support_tier" "$PHP_IV_HOST_PLATFORM"
}

php_iv_list_extensions() {
  local spec="$1"
  local manifest_file
  local ext_manifest

  manifest_file="$(php_iv_resolve_available_manifest "$spec")" || {
    php_iv_log error "Unknown PHP version: $spec"
    return "$PHP_IV_EXIT_VERSION_UNSUPPORTED"
  }

  php_iv_load_php_manifest "$manifest_file"

  while IFS= read -r ext_manifest; do
    php_iv_load_ext_manifest "$ext_manifest" "$PHP_IV_VERSION" "$PHP_IV_SERIES" "$PHP_IV_SUPPORT_TIER"
    if [[ "${PHP_IV_EXT_SUPPORTED:-0}" == "1" ]]; then
      printf '%s %s\n' "$PHP_IV_EXT_NAME" "$PHP_IV_EXT_PACKAGE_VERSION"
    fi
    unset -f php_iv_ext_manifest_load 2>/dev/null || true
  done < <(php_iv_available_ext_manifest_files)
}
