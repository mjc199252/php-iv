#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
export PHP_IV_PATH="$REPO_ROOT"
export PHP_IV_ROOT="$REPO_ROOT/.tmp/php-iv-root"

cleanup() {
  rm -rf "$PHP_IV_ROOT" "$REPO_ROOT/.tmp/test-output"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'assertion failed: expected output to contain [%s]\n' "$needle" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    printf 'assertion failed: expected output not to contain [%s]\n' "$needle" >&2
    exit 1
  fi
}

mkdir -p "$REPO_ROOT/.tmp/test-output"
cleanup
mkdir -p "$PHP_IV_ROOT"

while IFS= read -r file; do
  bash -n "$file"
done < <(find "$REPO_ROOT" -type f \( -name '*.sh' -o -path "$REPO_ROOT/bin/php-iv-core" \) ! -path "$REPO_ROOT/.git/*" | sort)

if command -v zsh >/dev/null 2>&1; then
  zsh -n "$REPO_ROOT/php-iv.zsh"
fi

available="$("$REPO_ROOT/bin/php-iv-core" list --available)"
assert_contains "$available" "7.4"
assert_contains "$available" "8.4"

info="$("$REPO_ROOT/bin/php-iv-core" info 8.4)"
assert_contains "$info" "release: 8.4.19"

ext_84="$("$REPO_ROOT/bin/php-iv-core" ext list 8.4)"
assert_contains "$ext_84" "redis 6.3.0"
assert_contains "$ext_84" "swoole 6.1.6"

ext_74="$("$REPO_ROOT/bin/php-iv-core" ext list 7.4)"
assert_contains "$ext_74" "redis 6.3.0"
assert_not_contains "$ext_74" "swoole 6.1.6"

mkdir -p \
  "$PHP_IV_ROOT/versions/8.4.19/bin" \
  "$PHP_IV_ROOT/versions/8.4.19/sbin" \
  "$PHP_IV_ROOT/versions/8.4.19/share/man" \
  "$PHP_IV_ROOT/etc/8.4.19/conf.d"

cat >"$PHP_IV_ROOT/versions/8.4.19/.php-iv-meta" <<'EOF'
PHP_IV_INSTALLED_VERSION="8.4.19"
PHP_IV_INSTALLED_SERIES="8.4"
PHP_IV_INSTALLED_TIER="current"
PHP_IV_INSTALLED_CONF_DIR="ignored"
EOF

env_output="$("$REPO_ROOT/bin/php-iv-core" env 8.4)"
assert_contains "$env_output" "PHP_IV_ACTIVE_VERSION"
assert_contains "$env_output" "PHPRC"

set +e
select_output="$("$REPO_ROOT/bin/php-iv-core" select 8.4 2>&1)"
select_status=$?
set -e
if [[ "$select_status" -eq 0 ]]; then
  printf 'assertion failed: direct select should require sourced bootstrap\n' >&2
  exit 1
fi
assert_contains "$select_output" "Select must run from a shell"

dry_run="$("$REPO_ROOT/bin/php-iv-core" install --dry-run 8.4 redis)"
assert_contains "$dry_run" "dry-run: install PHP 8.4.19"
assert_contains "$dry_run" "extension: redis 6.3.0"

set +e
legacy_output="$("$REPO_ROOT/bin/php-iv-core" install --dry-run 7.1 2>&1)"
legacy_status=$?
set -e
if [[ "$legacy_status" -eq 0 ]]; then
  printf 'assertion failed: legacy install should not be enabled yet\n' >&2
  exit 1
fi
assert_contains "$legacy_output" "Automated install is not enabled"

set +e
doctor_output="$("$REPO_ROOT/bin/php-iv-core" doctor 8.4 2>&1)"
doctor_status=$?
set -e
if [[ "$doctor_status" -ne 0 && "$doctor_status" -ne 10 ]]; then
  printf 'assertion failed: doctor returned unexpected status %s\n' "$doctor_status" >&2
  exit 1
fi
assert_contains "$doctor_output" "Host platform:"

bash -lc "export PHP_IV_PATH='$REPO_ROOT'; export PHP_IV_ROOT='$PHP_IV_ROOT'; source '$REPO_ROOT/php-iv.bash'; declare -F php-iv >/dev/null; php-iv select 8.4 >/dev/null; [[ \"\$PHP_IV_ACTIVE_VERSION\" == \"8.4.19\" ]]"

if command -v zsh >/dev/null 2>&1; then
  zsh -lc "export PHP_IV_PATH='$REPO_ROOT'; export PHP_IV_ROOT='$PHP_IV_ROOT'; source '$REPO_ROOT/php-iv.zsh'; whence -w php-iv >/dev/null; php-iv select 8.4 >/dev/null; [[ \"\$PHP_IV_ACTIVE_VERSION\" == \"8.4.19\" ]]"
fi

printf 'tests passed\n'
