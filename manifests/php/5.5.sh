PHP_IV_SERIES="5.5"
PHP_IV_VERSION="5.5.38"
PHP_IV_SOURCE_ARCHIVE="php-5.5.38.tar.xz"
PHP_IV_SOURCE_URL="https://www.php.net/distributions/php-5.5.38.tar.xz"
PHP_IV_SOURCE_SHA256=""
PHP_IV_SOURCE_DIR="php-5.5.38"
PHP_IV_SUPPORT_TIER="legacy"
PHP_IV_INSTALLABLE="1"
PHP_IV_SUPPORTED_PLATFORMS="linux-x86_64 linux-arm64 macos-x86_64 macos-arm64"
PHP_IV_EXPERIMENTAL_PLATFORMS="macos-arm64 linux-arm64"
PHP_IV_TOOLCHAIN_TOOLS=(pkg-config perl)
PHP_IV_TOOLCHAIN_COMPONENTS=(openssl-1.0.2u autoconf-2.69 bison-2.7.1)
PHP_IV_OPENSSL_COMPONENT="openssl-1.0.2u"
PHP_IV_CONFIGURE_ARGS=(
  --enable-cli
  --enable-fpm
  --enable-mbstring
  --enable-bcmath
  --enable-pcntl
  --enable-sockets
  --enable-opcache
  --with-zlib-dir=/usr
  --with-mysqli=mysqlnd
  --with-pdo-mysql=mysqlnd
)
PHP_IV_APPEND_CFLAGS="-Wno-error=implicit-function-declaration -Wno-error=deprecated-declarations"
PHP_IV_NOTES="Legacy automated install is enabled with isolated OpenSSL, Autoconf, and Bison toolchains."
