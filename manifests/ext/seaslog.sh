php_iv_ext_manifest_load() {
  local php_version="$1"

  PHP_IV_EXT_NAME="seaslog"
  PHP_IV_EXT_PACKAGE_VERSION="2.2.0"
  PHP_IV_EXT_SOURCE_ARCHIVE="seaslog-2.2.0.tgz"
  PHP_IV_EXT_SOURCE_URL="https://pecl.php.net/get/seaslog-2.2.0.tgz"
  PHP_IV_EXT_SOURCE_DIR="seaslog-2.2.0"
  PHP_IV_EXT_SUPPORTED="0"
  PHP_IV_EXT_REASON="seaslog 2.2.0 is enabled for PHP 7.0.0 or newer in this manifest."
  PHP_IV_EXT_CONFIGURE_ARGS=()
  PHP_IV_EXT_INI_LINES=("extension=seaslog.so")
  PHP_IV_EXT_NOTES="PECL seaslog release pinned by manifest."

  if php_iv_version_in_range "$php_version" "7.0.0" "8.4.99"; then
    PHP_IV_EXT_SUPPORTED="1"
    PHP_IV_EXT_REASON=""
  fi
}
