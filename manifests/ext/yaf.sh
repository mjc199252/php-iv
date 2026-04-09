php_iv_ext_manifest_load() {
  local php_version="$1"

  PHP_IV_EXT_NAME="yaf"
  PHP_IV_EXT_PACKAGE_VERSION="3.3.7"
  PHP_IV_EXT_SOURCE_ARCHIVE="yaf-3.3.7.tgz"
  PHP_IV_EXT_SOURCE_URL="https://pecl.php.net/get/yaf-3.3.7.tgz"
  PHP_IV_EXT_SOURCE_DIR="yaf-3.3.7"
  PHP_IV_EXT_SUPPORTED="0"
  PHP_IV_EXT_REASON="yaf 3.3.7 is enabled for PHP 7.0.0 or newer in this manifest."
  PHP_IV_EXT_CONFIGURE_ARGS=()
  PHP_IV_EXT_INI_LINES=("extension=yaf.so")
  PHP_IV_EXT_NOTES="PECL yaf release pinned by manifest."

  if php_iv_version_in_range "$php_version" "7.0.0" "8.4.99"; then
    PHP_IV_EXT_SUPPORTED="1"
    PHP_IV_EXT_REASON=""
  fi
}
