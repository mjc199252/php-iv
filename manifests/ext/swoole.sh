php_iv_ext_manifest_load() {
  local php_version="$1"

  PHP_IV_EXT_NAME="swoole"
  PHP_IV_EXT_PACKAGE_VERSION="6.1.6"
  PHP_IV_EXT_SOURCE_ARCHIVE="swoole-6.1.6.tgz"
  PHP_IV_EXT_SOURCE_URL="https://pecl.php.net/get/swoole-6.1.6.tgz"
  PHP_IV_EXT_SOURCE_DIR="swoole-6.1.6"
  PHP_IV_EXT_SUPPORTED="0"
  PHP_IV_EXT_REASON="swoole 6.1.6 is enabled for PHP 8.0.0 or newer in this manifest."
  PHP_IV_EXT_CONFIGURE_ARGS=()
  PHP_IV_EXT_INI_LINES=("extension=swoole.so")
  PHP_IV_EXT_NOTES="PECL swoole release pinned by manifest."

  if php_iv_version_in_range "$php_version" "8.0.0" "8.4.99"; then
    PHP_IV_EXT_SUPPORTED="1"
    PHP_IV_EXT_REASON=""
  fi
}
