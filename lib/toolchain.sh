#!/usr/bin/env bash

php_iv_reset_toolchain_manifest() {
  unset PHP_IV_TC_COMPONENT PHP_IV_TC_KIND PHP_IV_TC_NAME PHP_IV_TC_VERSION
  unset PHP_IV_TC_ARCHIVE PHP_IV_TC_URL PHP_IV_TC_SOURCE_DIR PHP_IV_TC_CONFIGURE_TARGET
  unset PHP_IV_TC_NOTES
}

php_iv_toolchain_manifest_path() {
  local component="$1"
  printf '%s/manifests/toolchain/%s.sh\n' "$PHP_IV_PATH" "$component"
}

php_iv_load_toolchain_manifest() {
  local component="$1"
  local manifest_file

  manifest_file="$(php_iv_toolchain_manifest_path "$component")"
  [[ -f "$manifest_file" ]] || return 1

  php_iv_reset_toolchain_manifest
  # shellcheck source=/dev/null
  source "$manifest_file"
}

php_iv_toolchain_component_prefix() {
  local component="$1"
  printf '%s/%s\n' "$PHP_IV_TOOLCHAINS_DIR" "$component"
}

php_iv_command_version() {
  local command_name="$1"
  local version_line=""

  case "$command_name" in
    autoconf|bison)
      version_line="$("$command_name" --version 2>/dev/null | head -1 | grep -Eo '[0-9]+(\.[0-9]+)+')"
      ;;
    *)
      version_line=""
      ;;
  esac

  printf '%s\n' "$version_line"
}

php_iv_toolchain_satisfies_system() {
  local component="$1"
  local system_version=""

  php_iv_load_toolchain_manifest "$component" || return 1

  case "$PHP_IV_TC_KIND" in
    autoconf|bison)
      if ! php_iv_command_exists "$PHP_IV_TC_KIND"; then
        return 1
      fi
      system_version="$(php_iv_command_version "$PHP_IV_TC_KIND")"
      [[ -n "$system_version" ]] || return 1
      php_iv_version_ge "$system_version" "$PHP_IV_TC_VERSION"
      ;;
    *)
      return 1
      ;;
  esac
}

php_iv_toolchain_component_ready() {
  local component="$1"
  local prefix

  prefix="$(php_iv_toolchain_component_prefix "$component")"
  php_iv_load_toolchain_manifest "$component" || return 1

  case "$PHP_IV_TC_KIND" in
    openssl)
      [[ -f "$prefix/lib/libssl.a" || -f "$prefix/lib/libssl.dylib" || -f "$prefix/lib64/libssl.a" ]]
      ;;
    autoconf)
      [[ -x "$prefix/bin/autoconf" ]] || php_iv_toolchain_satisfies_system "$component"
      ;;
    bison)
      [[ -x "$prefix/bin/bison" ]] || php_iv_toolchain_satisfies_system "$component"
      ;;
    *)
      return 1
      ;;
  esac
}

php_iv_toolchain_component_bin_dir() {
  local component="$1"
  local prefix

  prefix="$(php_iv_toolchain_component_prefix "$component")"
  if [[ -d "$prefix/bin" ]]; then
    printf '%s\n' "$prefix/bin"
  fi
}

php_iv_toolchain_component_pkgconfig_dirs() {
  local component="$1"
  local prefix

  prefix="$(php_iv_toolchain_component_prefix "$component")"
  [[ -d "$prefix/lib/pkgconfig" ]] && printf '%s\n' "$prefix/lib/pkgconfig"
  [[ -d "$prefix/lib64/pkgconfig" ]] && printf '%s\n' "$prefix/lib64/pkgconfig"
  [[ -d "$prefix/share/pkgconfig" ]] && printf '%s\n' "$prefix/share/pkgconfig"
}

php_iv_toolchain_component_include_dirs() {
  local component="$1"
  local prefix

  prefix="$(php_iv_toolchain_component_prefix "$component")"
  [[ -d "$prefix/include" ]] && printf '%s\n' "$prefix/include"
}

php_iv_toolchain_component_lib_dirs() {
  local component="$1"
  local prefix

  prefix="$(php_iv_toolchain_component_prefix "$component")"
  [[ -d "$prefix/lib" ]] && printf '%s\n' "$prefix/lib"
  [[ -d "$prefix/lib64" ]] && printf '%s\n' "$prefix/lib64"
}

php_iv_toolchain_openssl_target() {
  if [[ "$PHP_IV_HOST_OS" == "macos" ]]; then
    if [[ "$PHP_IV_HOST_ARCH" == "arm64" ]]; then
      printf 'darwin64-arm64-cc\n'
    else
      printf 'darwin64-x86_64-cc\n'
    fi
    return
  fi

  if [[ "$PHP_IV_HOST_ARCH" == "arm64" ]]; then
    printf 'linux-aarch64\n'
  else
    printf 'linux-x86_64\n'
  fi
}

php_iv_build_toolchain_component() {
  local component="$1"
  local prefix archive_path build_dir source_dir log_file status

  php_iv_load_toolchain_manifest "$component" || {
    php_iv_log error "Unknown toolchain component: $component"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  }

  prefix="$(php_iv_toolchain_component_prefix "$component")"
  archive_path="$PHP_IV_CACHE_DIR/$PHP_IV_TC_ARCHIVE"
  build_dir="$(php_iv_make_temp_dir "toolchain-${component}")"
  log_file="$PHP_IV_LOG_DIR/toolchain-${component}-$(date +%Y%m%d%H%M%S).log"

  php_iv_log info "Preparing toolchain component $component"

  if [[ ! -f "$archive_path" ]]; then
    php_iv_fetch_file "$PHP_IV_TC_URL" "$archive_path" || {
      php_iv_cleanup_dir "$build_dir"
      php_iv_log error "Download failed for toolchain component $component"
      return "$PHP_IV_EXIT_BUILD_FAILED"
    }
  fi

  php_iv_extract_archive "$archive_path" "$build_dir" || {
    php_iv_cleanup_dir "$build_dir"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  }

  source_dir="$build_dir/$PHP_IV_TC_SOURCE_DIR"
  mkdir -p "$prefix"

  (
    set -e
    cd "$source_dir"

    case "$PHP_IV_TC_KIND" in
      openssl)
        local target
        target="$(php_iv_toolchain_openssl_target)"
        ./Configure "$target" --prefix="$prefix" --openssldir="$prefix" no-tests no-shared
        make -j "$PHP_IV_MAKE_JOBS"
        make install_sw
        ;;
      autoconf|bison)
        ./configure --prefix="$prefix"
        make -j "$PHP_IV_MAKE_JOBS"
        make install
        ;;
      *)
        return 1
        ;;
    esac
  ) >"$log_file" 2>&1
  status=$?

  php_iv_cleanup_dir "$build_dir"

  if (( status != 0 )); then
    php_iv_log error "Failed to build toolchain component $component. See $log_file"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  fi

  return 0
}

php_iv_ensure_toolchain_component() {
  local component="$1"

  if php_iv_toolchain_component_ready "$component"; then
    return 0
  fi

  php_iv_build_toolchain_component "$component"
}

php_iv_export_toolchain_environment() {
  local component
  local path_entries=()
  local pkg_entries=()
  local include_entries=()
  local lib_entries=()
  local line

  for component in "${PHP_IV_TOOLCHAIN_COMPONENTS[@]}"; do
    php_iv_load_toolchain_manifest "$component" || continue

    if php_iv_toolchain_satisfies_system "$component"; then
      continue
    fi

    while IFS= read -r line; do
      [[ -n "$line" ]] && path_entries+=("$line")
    done < <(php_iv_toolchain_component_bin_dir "$component")

    while IFS= read -r line; do
      [[ -n "$line" ]] && pkg_entries+=("$line")
    done < <(php_iv_toolchain_component_pkgconfig_dirs "$component")

    while IFS= read -r line; do
      [[ -n "$line" ]] && include_entries+=("$line")
    done < <(php_iv_toolchain_component_include_dirs "$component")

    while IFS= read -r line; do
      [[ -n "$line" ]] && lib_entries+=("$line")
    done < <(php_iv_toolchain_component_lib_dirs "$component")
  done

  if [[ ${#path_entries[@]} -gt 0 ]]; then
    export PATH="$(IFS=:; printf '%s' "${path_entries[*]}"):$PATH"
  fi

  if [[ ${#pkg_entries[@]} -gt 0 ]]; then
    if [[ -n "${PKG_CONFIG_PATH:-}" ]]; then
      export PKG_CONFIG_PATH="$(IFS=:; printf '%s' "${pkg_entries[*]}"):$PKG_CONFIG_PATH"
    else
      export PKG_CONFIG_PATH="$(IFS=:; printf '%s' "${pkg_entries[*]}")"
    fi
  fi

  if [[ ${#include_entries[@]} -gt 0 ]]; then
    export CPPFLAGS="$(printf ' -I%s' "${include_entries[@]}")${CPPFLAGS:+ $CPPFLAGS}"
  fi

  if [[ ${#lib_entries[@]} -gt 0 ]]; then
    export LDFLAGS="$(printf ' -L%s' "${lib_entries[@]}")${LDFLAGS:+ $LDFLAGS}"
  fi
}

php_iv_ensure_toolchains() {
  local component

  for component in "${PHP_IV_TOOLCHAIN_COMPONENTS[@]}"; do
    php_iv_ensure_toolchain_component "$component" || return $?
  done

  php_iv_export_toolchain_environment
}

php_iv_toolchain_component_summary() {
  local component="$1"

  php_iv_load_toolchain_manifest "$component" || return 1

  if php_iv_toolchain_satisfies_system "$component"; then
    printf '%s(system)\n' "$component"
  else
    printf '%s(%s)\n' "$component" "$(php_iv_toolchain_component_prefix "$component")"
  fi
}
