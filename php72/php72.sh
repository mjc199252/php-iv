#!/bin/bash

# 设定各个目录
phpinstallpath="/usr/local/php"
phpinstallpathconf="/usr/local/phpconf"
NOW_PATH="$PHP_IV_PATH/php72"

# 创建文件安装目录
if [[ ! -d $phpinstallpath ]]; then
    sudo mkdir $phpinstallpath
    
    sudo chmod -R 777 $phpinstallpath
fi

if [[ ! -d $phpinstlalpathconf ]]; then
    sudo mkdir $phpinstallpathconf
    
    sudo chmod -R 777 $phpinstallpathconf
fi

# 获取系统
systemname=`uname -a`

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
fi

cd $NOW_PATH

# 开始PHP版本的下载与安装
if [[ ! -f "php-7.2.25.tar.gz" ]]; then 
	wget "https://github.com/php/php-src/archive/php-7.2.25.tar.gz"
fi	

tar -zxvf "php-7.2.25.tar.gz"

cd "php-src-php-7.2.25"

./buildconf --force
./configure --prefix=$phpinstallpath/php72/7.2.25_1 \
            --localstatedir=/usr/local/var \
            --sysconfdir=$phpinstallpathconf/php/7.2 \
            --with-config-file-path=$phpinstallpathconf/php/7.2 \
            --with-config-file-scan-dir=$phpinstallpathconf/php/7.2/conf.d \
            --mandir=$phpinstallpath/php72/7.2.25_1/share/man \
            --with-gd \
            --with-curl \
            --with-xsl=/usr \
            --with-xmlrpc \
            --with-openssl=/usr/local/openssl/1.1.1 \
            --with-pdo-pgsql \
            --with-png-dir=/usr/local/opt/libpng \
            --with-jpeg-dir=/usr/local/opt/jpeg \
            --with-libxml-dir=/usr/local/opt/libxml2 \
            --with-pdo-odbc=unixODBC,/usr/local/opt/unixodbc \
            --with-unixODBC=/usr/local/opt/unixodbc \
            --enable-fpm \
            --enable-ftp \
            --enable-dba \
            --enable-shmop \
            --enable-soap \
            --enable-sockets \
            --enable-sysvmsg \
            --enable-sysvsem \
            --enable-sysvshm \
            --enable-wddx \
            --enable-zip \
            --with-fpm-user=nobody \
            --with-fpm-group=nobody \
            --with-mysql-sock=/tmp/mysql.sock \
            --with-mysqli=mysqlnd \
            --with-pdo-mysql=mysqlnd \
            --disable-opcache \
            --enable-pcntl \
            --disable-opcache \
            --enable-zend-signals \


make

make install



if [[ -f "$phpinstallpath/php72/7.2.25_1/sbin/php72-fpm" ]]; then
	rm -rf "$phpinstallpath/php72/7.2.25_1/sbin/php72-fpm"
fi	

touch "$phpinstallpath/php72/7.2.25_1/sbin/php72-fpm" && chmod -R 755 "$phpinstallpath/php72/7.2.25_1/sbin/php72-fpm"
cat >> "$phpinstallpath/php72/7.2.25_1/sbin/php72-fpm" <<EOF
prefix=$phpinstallpath/php72/7.2.25_1
exec_prefix=\$prefix
php_fpm_BIN=\$exec_prefix/sbin/php-fpm
php_fpm_CONF=$phpinstallpathconf/php/7.2/php-fpm.conf
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

cp php.ini-development $phpinstallpathconf/php/7.2/php.ini

cp $phpinstallpathconf/php/7.2/php-fpm.conf.default $phpinstallpathconf/php/7.2/php-fpm.conf

chmod -R 755 $phpinstallpathconf/php/7.2/php.ini

chmod -R 755 $phpinstallpathconf/php/7.2/php-fpm.conf

cd $PHP_IV_PATH

if [[ $systemname =~ 'Darwin' ]]; then
    sed -i '' "149,150c\\
	;user=nobofy\\
	;group=nobody\\" $phpinstallpathconf/php/7.2/php-fpm.conf
else
	sed -i "149,150c\;user=nobody\\
	\;group=nobody" $phpinstallpathconf/php/7.2/php-fpm.conf
fi



