#!/usr/bin/env bash

php_iv_install() {
  local version_spec="$1"
  local extension="${2:-}"
  local dry_run="${3:-0}"
  local manifest_file
  local install_dir

  manifest_file="$(php_iv_resolve_available_manifest "$version_spec")" || {
    php_iv_log error "Unsupported PHP version: $version_spec"
    return "$PHP_IV_EXIT_VERSION_UNSUPPORTED"
  }

  php_iv_load_php_manifest "$manifest_file"

  if [[ "$PHP_IV_INSTALLABLE" != "1" ]]; then
    if ! php_iv_platform_supported "$PHP_IV_SUPPORTED_PLATFORMS" && [[ "$PHP_IV_HOST_PLATFORM" == "macos-arm64" && "$PHP_IV_SUPPORT_TIER" == "legacy" ]]; then
      php_iv_log error "PHP $PHP_IV_SERIES is recognized as ${PHP_IV_SUPPORT_TIER}. Automated install is not enabled in this phase, and macos-arm64 support remains experimental."
    else
      php_iv_log error "PHP $PHP_IV_SERIES is recognized as ${PHP_IV_SUPPORT_TIER}, but automated install is not enabled in this phase."
    fi
    return "$PHP_IV_EXIT_VERSION_UNSUPPORTED"
  fi

  if ! php_iv_platform_supported "$PHP_IV_SUPPORTED_PLATFORMS"; then
    php_iv_log error "PHP $PHP_IV_VERSION is not supported on $PHP_IV_HOST_PLATFORM."
    return "$PHP_IV_EXIT_VERSION_UNSUPPORTED"
  fi

  install_dir="$PHP_IV_VERSIONS_DIR/$PHP_IV_VERSION"

  php_iv_doctor "$PHP_IV_SERIES" || return $?

  if [[ "$dry_run" == "1" ]]; then
    printf 'dry-run: install PHP %s from %s\n' "$PHP_IV_VERSION" "$PHP_IV_SOURCE_URL"
    printf 'root: %s\n' "$install_dir"
    if [[ -n "$extension" ]]; then
      php_iv_validate_extension "$extension" "$PHP_IV_VERSION" "$PHP_IV_SERIES" "$PHP_IV_SUPPORT_TIER"
    fi
    return 0
  fi

  if [[ -x "$install_dir/bin/php-config" ]]; then
    php_iv_log info "PHP $PHP_IV_VERSION is already installed at $install_dir"
  else
    php_iv_install_php_from_manifest "$install_dir" || return $?
  fi

  if [[ -n "$extension" ]]; then
    php_iv_install_extension "$extension" "$install_dir" || return $?
  fi

  php_iv_log info "Install complete for PHP $PHP_IV_VERSION"
}

php_iv_install_php_from_manifest() {
  local install_dir="$1"
  local conf_dir="$PHP_IV_ETC_DIR/$PHP_IV_VERSION"
  local source_archive="$PHP_IV_CACHE_DIR/$PHP_IV_SOURCE_ARCHIVE"
  local build_dir=""
  local source_dir=""
  local log_file="$PHP_IV_LOG_DIR/php-${PHP_IV_VERSION}-$(date +%Y%m%d%H%M%S).log"
  local fpm_user fpm_group
  local status
  local configure_args=()

  php_iv_log info "Downloading PHP $PHP_IV_VERSION"
  if [[ ! -f "$source_archive" ]]; then
    php_iv_fetch_file "$PHP_IV_SOURCE_URL" "$source_archive" || {
      php_iv_log error "Download failed for $PHP_IV_SOURCE_URL"
      return "$PHP_IV_EXIT_BUILD_FAILED"
    }
  fi

  if ! php_iv_verify_sha256 "$source_archive" "${PHP_IV_SOURCE_SHA256:-}"; then
    php_iv_log error "SHA256 verification failed for $source_archive"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  fi

  build_dir="$(php_iv_make_temp_dir "php-${PHP_IV_SERIES}")"
  php_iv_extract_archive "$source_archive" "$build_dir" || {
    php_iv_cleanup_dir "$build_dir"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  }

  source_dir="$build_dir/$PHP_IV_SOURCE_DIR"
  mkdir -p "$install_dir" "$conf_dir/conf.d"

  fpm_user="$(id -un)"
  fpm_group="$(id -gn)"
  configure_args=(
    "--prefix=$install_dir"
    "--sysconfdir=$conf_dir"
    "--with-config-file-path=$conf_dir"
    "--with-config-file-scan-dir=$conf_dir/conf.d"
    "--with-fpm-user=$fpm_user"
    "--with-fpm-group=$fpm_group"
    "${PHP_IV_CONFIGURE_ARGS[@]}"
  )

  php_iv_log info "Building PHP $PHP_IV_VERSION (log: $log_file)"

  (
    set -e
    php_iv_prepare_build_environment
    cd "$source_dir"
    ./configure "${configure_args[@]}"
    make -j "$PHP_IV_MAKE_JOBS"
    make install
  ) >"$log_file" 2>&1
  status=$?

  if (( status != 0 )); then
    php_iv_cleanup_dir "$build_dir"
    php_iv_log error "Build failed for PHP $PHP_IV_VERSION. See $log_file"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  fi

  if [[ -f "$source_dir/php.ini-development" && ! -f "$conf_dir/php.ini" ]]; then
    cp "$source_dir/php.ini-development" "$conf_dir/php.ini"
  fi

  if [[ -f "$conf_dir/php-fpm.conf.default" && ! -f "$conf_dir/php-fpm.conf" ]]; then
    cp "$conf_dir/php-fpm.conf.default" "$conf_dir/php-fpm.conf"
  elif [[ -f "$install_dir/etc/php-fpm.conf.default" && ! -f "$conf_dir/php-fpm.conf" ]]; then
    cp "$install_dir/etc/php-fpm.conf.default" "$conf_dir/php-fpm.conf"
  fi

  if [[ -d "$install_dir/etc/php-fpm.d" && ! -d "$conf_dir/php-fpm.d" ]]; then
    cp -R "$install_dir/etc/php-fpm.d" "$conf_dir/php-fpm.d"
  fi

  php_iv_write_metadata "$install_dir" "$conf_dir"
  php_iv_cleanup_dir "$build_dir"
  return 0
}

php_iv_validate_extension() {
  local extension="$1"
  local php_version="$2"
  local php_series="$3"
  local support_tier="$4"
  local manifest_file="$PHP_IV_PATH/manifests/ext/${extension}.sh"

  if [[ ! -f "$manifest_file" ]]; then
    php_iv_log error "Unknown extension: $extension"
    return "$PHP_IV_EXIT_EXTENSION_UNSUPPORTED"
  fi

  php_iv_load_ext_manifest "$manifest_file" "$php_version" "$php_series" "$support_tier"
  unset -f php_iv_ext_manifest_load 2>/dev/null || true

  if [[ "${PHP_IV_EXT_SUPPORTED:-0}" != "1" ]]; then
    php_iv_log error "${PHP_IV_EXT_REASON:-$extension is not supported for PHP $php_version}"
    return "$PHP_IV_EXIT_EXTENSION_UNSUPPORTED"
  fi

  printf 'extension: %s %s\n' "$PHP_IV_EXT_NAME" "$PHP_IV_EXT_PACKAGE_VERSION"
  return 0
}

php_iv_install_extension() {
  local extension="$1"
  local install_dir="$2"
  local manifest_file="$PHP_IV_PATH/manifests/ext/${extension}.sh"
  local source_archive build_dir source_dir log_file status
  local php_config phpize conf_dir ext_dir ini_file
  local configure_args=()

  if [[ ! -f "$manifest_file" ]]; then
    php_iv_log error "Unknown extension: $extension"
    return "$PHP_IV_EXIT_EXTENSION_UNSUPPORTED"
  fi

  php_config="$install_dir/bin/php-config"
  phpize="$install_dir/bin/phpize"

  if [[ ! -x "$php_config" || ! -x "$phpize" ]]; then
    php_iv_log error "Missing phpize/php-config under $install_dir. Reinstall PHP before adding extensions."
    return "$PHP_IV_EXIT_BUILD_FAILED"
  fi

  php_iv_load_ext_manifest "$manifest_file" "$PHP_IV_VERSION" "$PHP_IV_SERIES" "$PHP_IV_SUPPORT_TIER"
  unset -f php_iv_ext_manifest_load 2>/dev/null || true

  if [[ "${PHP_IV_EXT_SUPPORTED:-0}" != "1" ]]; then
    php_iv_log error "${PHP_IV_EXT_REASON:-$extension is not supported for PHP $PHP_IV_VERSION}"
    return "$PHP_IV_EXIT_EXTENSION_UNSUPPORTED"
  fi

  source_archive="$PHP_IV_CACHE_DIR/$PHP_IV_EXT_SOURCE_ARCHIVE"
  log_file="$PHP_IV_LOG_DIR/ext-${extension}-${PHP_IV_VERSION}-$(date +%Y%m%d%H%M%S).log"

  php_iv_log info "Downloading extension $extension"
  if [[ ! -f "$source_archive" ]]; then
    php_iv_fetch_file "$PHP_IV_EXT_SOURCE_URL" "$source_archive" || {
      php_iv_log error "Download failed for $PHP_IV_EXT_SOURCE_URL"
      return "$PHP_IV_EXIT_BUILD_FAILED"
    }
  fi

  build_dir="$(php_iv_make_temp_dir "ext-${extension}")"
  php_iv_extract_archive "$source_archive" "$build_dir" || {
    php_iv_cleanup_dir "$build_dir"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  }

  source_dir="$build_dir/$PHP_IV_EXT_SOURCE_DIR"
  conf_dir="$PHP_IV_ETC_DIR/$PHP_IV_VERSION/conf.d"
  mkdir -p "$conf_dir"

  configure_args=("--with-php-config=$php_config")
  if [[ ${#PHP_IV_EXT_CONFIGURE_ARGS[@]} -gt 0 ]]; then
    configure_args+=("${PHP_IV_EXT_CONFIGURE_ARGS[@]}")
  fi

  php_iv_log info "Building extension $extension (log: $log_file)"

  (
    set -e
    php_iv_prepare_build_environment
    cd "$source_dir"
    "$phpize"
    ./configure "${configure_args[@]}"
    make -j "$PHP_IV_MAKE_JOBS"
    make install
  ) >"$log_file" 2>&1
  status=$?

  if (( status != 0 )); then
    php_iv_cleanup_dir "$build_dir"
    php_iv_log error "Build failed for extension $extension. See $log_file"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  fi

  ext_dir="$("$php_config" --extension-dir)"
  ini_file="$conf_dir/50-${PHP_IV_EXT_NAME}.ini"

  if [[ ! -d "$ext_dir" ]]; then
    php_iv_cleanup_dir "$build_dir"
    php_iv_log error "Extension directory does not exist: $ext_dir"
    return "$PHP_IV_EXIT_BUILD_FAILED"
  fi

  printf '%s\n' "${PHP_IV_EXT_INI_LINES[@]}" >"$ini_file"
  php_iv_cleanup_dir "$build_dir"
  php_iv_log info "Installed extension $extension"
  return 0
}

php_iv_select_installed() {
  local spec="$1"
  local record version series install_dir

  record="$(php_iv_resolve_installed_record "$spec")" || {
    php_iv_log error "PHP version $spec is not installed. Use php-iv install first."
    return "$PHP_IV_EXIT_VERSION_UNSUPPORTED"
  }

  IFS='|' read -r version series install_dir <<<"$record"

  ln -sfn "$install_dir" "$PHP_IV_CURRENT_LINK"
  php_iv_log info "Activated PHP $version"
}
