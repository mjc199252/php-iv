#!/bin/bash
wget "https://pecl.php.net/get/yaf-2.3.5.tgz"
tar -zxvf "yaf-2.3.5.tgz"
cd yaf-2.3.5
phpize
./configure --with-php-config=/usr/local/php/php56/5.6.33_1/bin/php-config
make && make install
cd $PHP_IV_PATH