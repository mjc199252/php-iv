#!/bin/bash

phpinstallpath="/usr/local/php"
phpinstallpathconf="/usr/local/phpconf"
NOW_PATH="$PHP_IV_PATH/php55"

# 创建文件安装目录
if [[ ! -d $phpinstallpath ]]; then
    sudo mkdir $phpinstallpath
    
    sudo chmod -R 777 $phpinstallpath
fi

if [[ ! -d $phpinstallpathconf ]]; then
    sudo mkdir $phpinstallpathconf
    
    sudo chmod -R 777 $phpinstallpathconf
fi

bison --version | head -1 | awk '{print $NF}'

if [ $? -eq  0 ]; then

	 b_t=$(bison --version | head -1 | awk '{print $NF}')

	 bison_v=${rt/./0}  

	if[ bison_v -lt 20401 -o bison_v -gt 20401 ]; then

		wget "http://ftp.gnu.org/gnu/bison/bison-2.4.1.tar.gz" 

		tar -zxvf bison-2.4.1.tar.gz

		cd bison-2.4.1

		./configure && make && make install

		cd ../

	  	rm -rf bison-2.4.1.tar.gz bison-2.4.1
	fi
else
		wget "http://ftp.gnu.org/gnu/bison/bison-2.4.1.tar.gz" 

		tar -zxvf bison-2.4.1.tar.gz

		cd bison-2.4.1

		./configure && make && make install

		cd ../

	  	rm -rf bison-2.4.1.tar.gz bison-2.4.1
fi


# 获取系统名称
systemname=`uname -a`

if [[ ! -d "/usr/local/openssl/1.0.2" ]]; then

	if [[ ! -f "openssl-1.0.2t.tar.gz" ]]; then
		wget "https://www.openssl.org/source/openssl-1.0.2t.tar.gz"
	fi	

    tar -zxvf "openssl-1.0.2t.tar.gz"

    cd "openssl-1.0.2t"

    if [[ $systemname =~ 'Darwin' ]]; then
        sudo make clean

    	sudo ./Configure darwin64-x86_64-cc --prefix=/usr/local/openssl/1.0.2 --openssldir=/usr/local/openssl/1.0.2 \

    	sudo make

    	sudo make install
    else
        sudo ./config --prefix=/usr/local/openssl/1.0.2 --openssldir=/usr/local/openssl/1.0.2 \

        sudo make

        sudo make install
    fi

    cd ../

    sudo rm -rf "openssl-1.0.2t.tar.gz" "openssl-1.0.2t"

fi


if [[ ! -f "php-5.5.38.tar.gz" ]]; then 
	wget "https://github.com/php/php-src/archive/php-5.5.38.tar.gz"
	
fi	

tar -zxvf "php-5.5.38.tar.gz"

cd "php-src-php-5.5.38"

./buildconf --force

./configure --prefix=$phpinstallpath/php55/5.5.38_1 \
            --localstatedir=/usr/local/var \
            --sysconfdir=$phpinstallpathconf/php/5.5 \
            --with-config-file-path=$phpinstallpathconf/php/5.5 \
            --with-config-file-scan-dir=$phpinstallpathconf/php/5.5/conf.d \
            --mandir=$phpinstallpath/php55/5.5.38_1/share/man \
            --enable-inline-optimization \
            --disable-debug \
            --disable-rpath \
            --enable-shared \
            --enable-opcache \
            --enable-session \
            --enable-fpm \
            --with-fpm-user=nobody \
            --with-fpm-group=nobody \
            --with-mysql=mysqlnd \
            --with-mysqli=mysqlnd \
            --with-pdo-mysql=mysqlnd \
            --enable-mbstring \
            --with-iconv \
            --with-mcrypt \
            --with-zlib-dir \
            --with-pcre-regex \
            --with-iconv \
            --with-bz2 \
            --with-sqlite3 \
            --with-mcrypt \
            --with-mhash \
            --with-jpeg-dir \
            --with-png-dir \
            --disable-debug 
            --with-pcre-dir \
            --with-libxml-dir \
            --with-mhash \
            --with-gd \
            --enable-ftp \
            --with-xsl \
            --enable-zip \
            --with-openssl=/usr/local/openssl/1.0.2 \
            --enable-mysqlnd-compression-support \
            --with-pear \
            --enable-bcmath \
            --enable-soap \
            --enable-pcntl \
            --enable-shmop \
            --enable-json \
            --enable-sysvmsg \
            --enable-sysvsem \
            --enable-sysvshm \
            --enable-sockets \
            --with-curl \


make

make install


if [[ -f "$phpinstallpath/php55/5.5.38_1/sbin/php55-fpm" ]]; then
	rm -rf "$phpinstallpath/php55/5.5.38_1/sbin/php55-fpm"
fi	


touch "$phpinstallpath/php55/5.5.38_1/sbin/php55-fpm" && chmod -R 755 "$phpinstallpath/php55/5.5.38_1/sbin/php55-fpm"
cat >> "$phpinstallpath/php55/5.5.38_1/sbin/php55-fpm" <<EOF
prefix=$phpinstallpath/php55/5.5.38_1
exec_prefix=\$prefix
php_fpm_BIN=\$exec_prefix/sbin/php-fpm
php_fpm_CONF=$phpinstallpathconf/php/5.5/php-fpm.conf
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

cp php.ini-development $phpinstallpathconf/php/5.5/php.ini

cp $phpinstallpathconf/php/5.5/php-fpm.conf.default $phpinstallpathconf/php/5.5/php-fpm.conf

chmod -R 755 $phpinstallpathconf/php/5.5/php.ini

chmod -R 755 $phpinstallpathconf/php/5.5/php-fpm.conf

cd ../

sudo rm -rf "php-5.5.38.tar.gz" "php-src-php-5.5.38"

if [[ $systemname =~ 'Darwin' ]]; then
    sed -i '' "149,150c\\
	;user=nobofy\\
	;group=nobody\\" $phpinstallpathconf/php/5.5/php-fpm.conf
else
	sed -i "149,150c\;user=nobody\\
	\;group=nobody" $phpinstallpathconf/php/5.5/php-fpm.conf
fi
