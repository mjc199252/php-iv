PHP_IV_SERIES="7.3"
PHP_IV_VERSION="7.3.32"
PHP_IV_SOURCE_ARCHIVE="php-7.3.32.tar.xz"
PHP_IV_SOURCE_URL="https://www.php.net/distributions/php-7.3.32.tar.xz"
PHP_IV_SOURCE_SHA256="94effa250b80f031e77fbd98b6950c441157a2a8f9e076ee68e02f5b0b7a3fd9"
PHP_IV_SOURCE_DIR="php-7.3.32"
PHP_IV_SUPPORT_TIER="legacy"
PHP_IV_INSTALLABLE="1"
PHP_IV_SUPPORTED_PLATFORMS="linux-x86_64 linux-arm64 macos-x86_64 macos-arm64"
PHP_IV_EXPERIMENTAL_PLATFORMS="macos-arm64"
PHP_IV_TOOLCHAIN_TOOLS=(pkg-config perl)
PHP_IV_TOOLCHAIN_COMPONENTS=(openssl-1.1.1w autoconf-2.69 bison-3.8.2)
PHP_IV_OPENSSL_COMPONENT="openssl-1.1.1w"
PHP_IV_CONFIGURE_ARGS=(
  --enable-cli
  --enable-fpm
  --enable-mbstring
  --enable-bcmath
  --enable-pcntl
  --enable-sockets
  --enable-opcache
  --with-zlib
  --with-mysqli=mysqlnd
  --with-pdo-mysql=mysqlnd
)
PHP_IV_APPEND_CFLAGS="-Wno-error=implicit-function-declaration"
PHP_IV_NOTES="Legacy automated install is enabled with isolated OpenSSL, Autoconf, and Bison toolchains."
