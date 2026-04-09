PHP_IV_SERIES="7.4"
PHP_IV_VERSION="7.4.33"
PHP_IV_SOURCE_ARCHIVE="php-7.4.33.tar.xz"
PHP_IV_SOURCE_URL="https://www.php.net/distributions/php-7.4.33.tar.xz"
PHP_IV_SOURCE_SHA256="924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927"
PHP_IV_SOURCE_DIR="php-7.4.33"
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
PHP_IV_NOTES="Current-phase install target. PHP 7.4 is EOL upstream, but remains available for compatibility."
