#!/usr/bin/env bash

php_iv_doctor_required_tools() {
  local version_spec="${1:-}"
  local tools=(tar make)

  if php_iv_command_exists cc; then
    :
  elif php_iv_command_exists clang; then
    :
  elif php_iv_command_exists gcc; then
    :
  else
    tools+=("__compiler__")
  fi

  tools+=(pkg-config)

  if [[ -n "$version_spec" ]]; then
    local manifest_file
    manifest_file="$(php_iv_resolve_available_manifest "$version_spec" 2>/dev/null || true)"
    if [[ -n "$manifest_file" ]]; then
      php_iv_load_php_manifest "$manifest_file"
      if [[ ${#PHP_IV_TOOLCHAIN_TOOLS[@]} -gt 0 ]]; then
        tools+=("${PHP_IV_TOOLCHAIN_TOOLS[@]}")
      fi
    fi
  fi

  printf '%s\n' "${tools[@]}"
}

php_iv_doctor_fetcher_status() {
  if php_iv_fetcher >/dev/null 2>&1; then
    printf '[ok] downloader: %s\n' "$(php_iv_fetcher)"
    return 0
  fi

  printf '[missing] downloader: install curl or wget\n'
  return 1
}

php_iv_doctor_hint() {
  if [[ "$PHP_IV_HOST_OS" == "macos" ]]; then
    cat <<'EOF'
Suggested macOS dependencies:
  brew install autoconf bison re2c pkgconf openssl@3 curl libxml2 sqlite zlib libzip
EOF
    return
  fi

  if php_iv_command_exists apt-get; then
    cat <<'EOF'
Suggested Debian/Ubuntu dependencies:
  sudo apt-get update
  sudo apt-get install -y build-essential autoconf bison re2c pkg-config curl ca-certificates libssl-dev libxml2-dev libsqlite3-dev libcurl4-openssl-dev libzip-dev libonig-dev
EOF
    return
  fi

  if php_iv_command_exists dnf; then
    cat <<'EOF'
Suggested Fedora/RHEL dependencies:
  sudo dnf install -y gcc gcc-c++ make autoconf bison re2c pkgconf-pkg-config curl openssl-devel libxml2-devel sqlite-devel libcurl-devel libzip-devel oniguruma-devel
EOF
    return
  fi

  cat <<'EOF'
Install a compiler toolchain, autoconf, pkg-config, curl/wget, and the OpenSSL/libxml/sqlite/curl development headers for your platform.
EOF
}

php_iv_doctor() {
  local version_spec="${1:-}"
  local status=0
  local tool
  local manifest_file

  printf 'Host platform: %s\n' "$PHP_IV_HOST_PLATFORM"
  printf 'Install root: %s\n' "$PHP_IV_ROOT"

  if [[ -n "$version_spec" ]]; then
    if manifest_file="$(php_iv_resolve_available_manifest "$version_spec" 2>/dev/null)"; then
      php_iv_load_php_manifest "$manifest_file"
      printf 'Target version: %s (%s)\n' "$PHP_IV_VERSION" "$PHP_IV_SUPPORT_TIER"
      if [[ -n "${PHP_IV_NOTES:-}" ]]; then
        printf 'Notes: %s\n' "$PHP_IV_NOTES"
      fi
      if [[ -n "${PHP_IV_EXPERIMENTAL_PLATFORMS:-}" ]] && [[ " $PHP_IV_EXPERIMENTAL_PLATFORMS " == *" $PHP_IV_HOST_PLATFORM "* ]]; then
        printf 'Experimental: yes on %s\n' "$PHP_IV_HOST_PLATFORM"
      fi
      if [[ ${#PHP_IV_TOOLCHAIN_COMPONENTS[@]} -gt 0 ]]; then
        printf 'Managed toolchains: %s\n' "${PHP_IV_TOOLCHAIN_COMPONENTS[*]}"
      fi
    fi
  fi

  if ! php_iv_doctor_fetcher_status; then
    status=1
  fi

  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    case "$tool" in
      __compiler__)
        printf '[missing] compiler: install clang, gcc, or cc\n'
        status=1
        ;;
      *)
        if php_iv_command_exists "$tool"; then
          printf '[ok] %s: %s\n' "$tool" "$(command -v "$tool")"
        else
          printf '[missing] %s\n' "$tool"
          status=1
        fi
        ;;
    esac
  done < <(php_iv_doctor_required_tools "$version_spec")

  if (( status != 0 )); then
    php_iv_doctor_hint
    return "$PHP_IV_EXIT_DEPENDENCY"
  fi

  printf 'Doctor checks passed.\n'
  return 0
}
