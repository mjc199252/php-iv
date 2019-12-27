#!/bin/bash

phpinstallpath="/usr/local/php"
phpinstallpathconf="/usr/local/phpconf"
NOW_PATH="$PHP_IV_PATH/php70"

# 创建文件安装目录

if [[ ! -d $phpinstallpath ]]; then
    sudo mkdir $phpinstallpath
    
    sudo chmod -R 777 $phpinstallpath
fi

if [[ ! -d $phpinstlalpathconf ]]; then
    sudo mkdir $phpinstallpathconf
    
    sudo chmod -R 777 $phpinstallpathconf
fi

bison --version | head -1 | awk '{print $NF}'

if [ $? -eq  0 ]; then

	 b_t=$(bison --version | head -1 | awk '{print $NF}')

	 bison_v=${rt/./0}  

	if[ bison_v -lt 30402 ]; then

		wget "http://ftp.gnu.org/gnu/bison/bison-3.4.2.tar.gz" 

		tar -zxvf bison-3.4.2.tar.gz

		cd bison-3.4.2

		./configure && make && make install

		cd ../

	  	rm -rf bison-3.4.2.tar.gz bison-3.4.2
	fi
else
		wget "http://ftp.gnu.org/gnu/bison/bison-3.4.2.tar.gz" 
		
		tar -zxvf bison-3.4.2.tar.gz

		cd bison-3.4.2

		./configure && make && make install

		cd ../

	  	rm -rf bison-3.4.2.tar.gz bison-3.4.2
fi



# 获取系统名称
systemname=`uname -a`

# 判断是否下载安装openssl

if [[ ! -d "/usr/local/openssl/1.1.1" ]]; then

	if [[ ! -f "openssl-1.1.1d.tar.gz" ]]; then
    	wget "https://www.openssl.org/source/openssl-1.1.1d.tar.gz"
	fi	

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

    cd ../

    sudo rm -rf "openssl-1.1.1d.tar.gz" "openssl-1.1.1d"
fi

# 开始PHP版本的下载与安装
if [[ ! -f "php-7.0.27.tar.gz" ]]; then 
	wget "https://github.com/php/php-src/archive/php-7.0.27.tar.gz"
fi	

tar -zxvf "php-7.0.27.tar.gz"

cd "php-src-php-7.0.27"

./buildconf --force
./configure --prefix=$phpinstallpath/php70/7.0.27_1 \
			--localstatedir=/usr/local/var \
			--sysconfdir=$phpinstallpathconf/php/7.0 \
			--with-config-file-path=$phpinstallpathconf/php/7.0 \
			--with-config-file-scan-dir=$phpinstallpathconf/php/7.0/conf.d \
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
			--enable-session \
			--enable-wddx \
			--enable-zip \
			--with-freetype-dir \
			--with-gd \
			--with-gettext \
			--with-zlib-dir \
            --with-iconv \
			--with-icu-dir \
			--with-pcre-regex \
			--with-pcre-dir \
			--with-jpeg-dir \
			--with-mhash \
			--with-png-dir \
			--with-xmlrpc \
			--with-zlib \
			--with-readline \
			--without-gmp \
			--without-snmp \
			--with-libxml-dir \
			--with-bz2 \
			--enable-mysqlnd-compression-support \
			--with-openssl=/usr/local/openssl/1.1.1 \
			--enable-fpm \
			--with-fpm-user=nobody \
			--with-fpm-group=nobody \
			--with-curl \
			--with-xsl \
			--with-ldap \
			--with-ldap-sasl \
			--with-mysqli=mysqlnd \
			--with-pdo-mysql=mysqlnd \
			--with-pdo-pgsql \
			--disable-opcache \
			--enable-pcntl \
			--without-pear \
			--enable-dtrace \
			--disable-phpdbg \
			--enable-zend-signals \


make

make install

if [[ -f "$phpinstallpath/php70/7.0.27_1/sbin/php70-fpm" ]]; then
	rm -rf "$phpinstallpath/php70/7.0.27_1/sbin/php70-fpm"
fi	


touch "$phpinstallpath/php70/7.0.27_1/sbin/php70-fpm" && chmod -R 755 "$phpinstallpath/php70/7.0.27_1/sbin/php70-fpm"
cat >> "$phpinstallpath/php70/7.0.27_1/sbin/php70-fpm" <<EOF
prefix=$phpinstallpath/php70/7.0.27_1
exec_prefix=\$prefix
php_fpm_BIN=\$exec_prefix/sbin/php-fpm
php_fpm_CONF=$phpinstallpathconf/php/7.0/php-fpm.conf
php_fpm_PID=/usr/local/var/run/php-fpm.pid
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

cp php.ini-development $phpinstallpathconf/php/7.0/php.ini

cp $phpinstallpathconf/php/7.0/php-fpm.conf.default $phpinstallpathconf/php/7.0/php-fpm.conf

cp $phpinstallpathconf/php/7.0/php-fpm.d/www.conf.default $phpinstallpathconf/php/7.0/php-fpm.d/www.conf

chmod -R 755 $phpinstallpathconf/php/7.0/php.ini

chmod -R 755 $phpinstallpathconf/php/7.0/php-fpm.conf

chmod -R 755 $phpinstallpathconf/php/7.0/php-fpm.d/www.conf

cd ../

sudo rm -rf "php-7.0.27.tar.gz" "php-src-php-7.0.27"

if [[ $systemname =~ 'Darwin' ]]; then
    sed -i '' "23,24c\\
	;user=nobofy\\
	;group=nobody\\" $phpinstallpathconf/php/7.1/php-fpm.d/www.conf
else
	sed -i "23,24c\;user=nobody\\
	\;group=nobody" $phpinstallpathconf/php/7.1/php-fpm.d/www.conf
fi



