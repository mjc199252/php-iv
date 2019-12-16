#!/bin/bash

phpinstallpath="/usr/local/php"
phpinstlalpathconf="/usr/local/phpconf"
if [[ ! -d $phpinstallpath ]]; then
    mkdir $phpinstallpath
fi

if [[ ! -d $phpinstlalpathconf ]]; then
    mkdir $phpinstlalpathconf
fi

systemname=`uname -a`

if [[ ! -d "/usr/local/openssl/1.1.1" ]]; then
    wget "https://www.openssl.org/source/openssl-1.1.1d.tar.gz"
    tar -zxvf "openssl-1.1.1d.tar.gz"
    cd "openssl-1.1.1d"
    if [[ $systemname =~ 'Darwin' ]]; then
        sudo make clean
    	sudo ./Configure darwin64-x86_64-cc --prefix=/usr/local/openssl/1.1.1 --openssldir=/usr/local/openssl/1.1.1 --shared \
    	sudo make
    	sudo make install
    else
        sudo ./config --prefix=/usr/local/openssl/1.1.1 --openssldir=/usr/local/openssl/1.1.1 \
        sudo make
        sudo make install
    fi
fi

wget "https://github.com/php/php-src/archive/php-7.0.27.tar.gz"
tar -zxvf "php-7.0.27.tar.gz"
cd "php-src-php-7.0.27"

./buildconf --force
./configure --prefix=$phpinstallpath/php70/7.0.27_1 \
			--localstatedir=/usr/local/var \
			--sysconfdir=$phpinstlalpathconf/php/7.0 \
			--with-config-file-path=$phpinstlalpathconf/php/7.0 \
			--with-config-file-scan-dir=$phpinstlalpathconf/php/7.0/conf.d \
			--mandir=$phpinstallpath/php70/7.0.27_1/share/man \
			--enable-bcmath \
			--enable-calendar \
			--enable-dba \
			--enable-exif \
			--enable-ftp \
			--enable-gd-native-ttf \
			--enable-mbregex \
			--enable-mbstring \
			--enable-shmop \
			--enable-soap \
			--enable-sockets \
			--enable-sysvmsg \
			--enable-sysvsem \
			--enable-sysvshm \
			--enable-wddx \
			--enable-zip \
			--with-freetype-dir=/usr/local/opt/freetype \
			--with-gd \
			--with-gettext=/usr/local/opt/gettext \
			--with-iconv-dir=/usr/local/libiconv \
			--with-icu-dir=/usr/local/opt/icu4c \
			--with-jpeg-dir=/usr/local/opt/jpeg \
			--with-kerberos=/usr \
			--with-mhash \
			--with-ndbm=/usr \
			--with-png-dir=/usr/local/opt/libpng \
			--with-xmlrpc \
			--with-zlib=/usr \
			--with-readline=/usr/local/opt/readline \
			--without-gmp --without-snmp \
			--with-libxml-dir=/usr/local/opt/libxml2 \
			--with-pdo-odbc=unixODBC,/usr/local/opt/unixodbc \
			--with-unixODBC=/usr/local/opt/unixodbc \
			--with-bz2=/usr \
			--with-openssl=/usr/local/openssl/1.1.1 \
			--enable-fpm \
			--with-fpm-user=_www \
			--with-fpm-group=_www \
			--with-curl \
			--with-xsl=/usr \
			--with-ldap \
			--with-ldap-sasl=/usr \
			--with-mysql-sock=/tmp/mysql.sock \
			--with-mysqli=mysqlnd \
			--with-pdo-mysql=mysqlnd \
			--with-pdo-pgsql \
			--disable-opcache \
			--enable-pcntl \
			--without-pear \
			--enable-dtrace \
			--disable-phpdbg \
			--enable-zend-signals \

make && make install


touch "$phpinstallpath/php70/7.0.27_1/sbin/php70-fpm" && chmod -R 755 "$phpinstallpath/php70/7.0.27_1/sbin/php70-fpm"
cat >> "$phpinstallpath/php70/7.0.27_1/sbin/php70-fpm" <<EOF
prefix=\${phpinstallpath}/php70/7.0.27_1
exec_prefix=\${prefix}
php_fpm_BIN=\${exec_prefix}/sbin/php-fpm
php_fpm_CONF=\${phpinstallpathconf}/php/7.0/php-fpm.conf
php_fpm_PID=\${exec_prefix}/run/php-fpm.pid
php_opts="--fpm-config \$php_fpm_CONF --pid \$php_fpm_PID"
wait_for_pid () {
	try=0
	while test \$try -lt 35 ; do
		case "\$1" in
			'created')
			if [ -f "\$2" ] ; then
				try=''
				break
			fi
			;;

			'removed')
			if [ ! -f "\$2" ] ; then
				try=''
				break
			fi
			;;
		esac

		echo -n .
		try=\`expr \$try + 1\`
		sleep 1

	done

}

case "\$1" in
	start)
		echo -n "Starting php-fpm "

		\$php_fpm_BIN --daemonize \$php_opts

		if [ "\$?" != 0 ] ; then
			echo " failed"
			exit 1
		fi

		wait_for_pid created \$php_fpm_PID

		if [ -n "\$try" ] ; then
			echo " failed"
			exit 1
		else
			echo " done"
		fi
	;;

	stop)
		echo -n "Gracefully shutting down php-fpm "

		if [ ! -r \$php_fpm_PID ] ; then
			echo "warning, no pid file found - php-fpm is not running ?"
			exit 1
		fi

		kill -QUIT \`cat \$php_fpm_PID\`

		wait_for_pid removed \$php_fpm_PID

		if [ -n "\$try" ] ; then
			echo " failed. Use force-quit"
			exit 1
		else
			echo " done"
		fi
	;;

	status)
		if [ ! -r \$php_fpm_PID ] ; then
			echo "php-fpm is stopped"
			exit 0
		fi

		PID=\`cat \$php_fpm_PID\`
		if ps -p \$PID | grep -q \$PID; then
			echo "php-fpm (pid \$PID) is running..."
		else
			echo "php-fpm dead but pid file exists"
		fi
	;;

	force-quit)
		echo -n "Terminating php-fpm "

		if [ ! -r \$php_fpm_PID ] ; then
			echo "warning, no pid file found - php-fpm is not running ?"
			exit 1
		fi

		kill -TERM \`cat \$php_fpm_PID\`

		wait_for_pid removed \$php_fpm_PID

		if [ -n "\$try" ] ; then
			echo " failed"
			exit 1
		else
			echo " done"
		fi
	;;

	restart)
		\$0 stop
		\$0 start
	;;

	reload)

		echo -n "Reload service php-fpm "

		if [ ! -r \$php_fpm_PID ] ; then
			echo "warning, no pid file found - php-fpm is not running ?"
			exit 1
		fi

		kill -USR2 \`cat \$php_fpm_PID\`

		echo " done"
	;;

	configtest)
		\$php_fpm_BIN -t
	;;

	*)
		echo "Usage: \$0 {start|stop|force-quit|restart|reload|status|configtest}"
		exit 1
	;;
esac
EOF
cp php.ini-development $phpinstlalpathconf/php/7.0/php.ini