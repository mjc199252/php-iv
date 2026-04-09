php_iv_ext_manifest_load() {
  local php_version="$1"

  PHP_IV_EXT_NAME="redis"
  PHP_IV_EXT_PACKAGE_VERSION="6.3.0"
  PHP_IV_EXT_SOURCE_ARCHIVE="redis-6.3.0.tgz"
  PHP_IV_EXT_SOURCE_URL="https://pecl.php.net/get/redis-6.3.0.tgz"
  PHP_IV_EXT_SOURCE_DIR="redis-6.3.0"
  PHP_IV_EXT_SUPPORTED="0"
  PHP_IV_EXT_REASON="redis 6.3.0 requires PHP 7.4.0 or newer."
  PHP_IV_EXT_CONFIGURE_ARGS=()
  PHP_IV_EXT_INI_LINES=("extension=redis.so")
  PHP_IV_EXT_NOTES="PECL redis release pinned by manifest."

  if php_iv_version_in_range "$php_version" "7.4.0" "8.4.99"; then
    PHP_IV_EXT_SUPPORTED="1"
    PHP_IV_EXT_REASON=""
  fi
}
