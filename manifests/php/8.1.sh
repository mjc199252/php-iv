PHP_IV_SERIES="8.1"
PHP_IV_VERSION="8.1.34"
PHP_IV_SOURCE_ARCHIVE="php-8.1.34.tar.xz"
PHP_IV_SOURCE_URL="https://www.php.net/distributions/php-8.1.34.tar.xz"
PHP_IV_SOURCE_SHA256="ffa9e0982e82eeaea848f57687b425ed173aa278fe563001310ae2638db5c251"
PHP_IV_SOURCE_DIR="php-8.1.34"
PHP_IV_SUPPORT_TIER="current"
PHP_IV_INSTALLABLE="1"
PHP_IV_SUPPORTED_PLATFORMS="linux-x86_64 linux-arm64 macos-x86_64 macos-arm64"
PHP_IV_TOOLCHAIN_TOOLS=(pkg-config autoconf)
PHP_IV_CONFIGURE_ARGS=(
  --enable-cli
  --enable-fpm
  --enable-mbstring
  --enable-bcmath
  --enable-pcntl
  --enable-sockets
  --enable-opcache
  --with-zlib
  --with-openssl
  --with-mysqli=mysqlnd
  --with-pdo-mysql=mysqlnd
)
PHP_IV_NOTES="Current-phase install target. PHP 8.1 is upstream EOL and retained for compatibility."
