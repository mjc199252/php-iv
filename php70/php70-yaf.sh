#!/bin/bash
wget "https://pecl.php.net/get/yaf-3.0.4.tgz"
tar -zxvf "yaf-3.0.4.tgz"
cd yaf-3.0.4
phpize
./configure --with-php-config=/usr/local/php/php70/7.0.27_1/bin/php-config
make && make install
cd $PHP_IV_PATH