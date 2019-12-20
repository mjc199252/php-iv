#!/bin/bash
wget "https://pecl.php.net/get/yaf-3.0.9.tgz"
tar -zxvf "yaf-3.0.9.tgz"
cd yaf-3.0.9
phpize
./configure --with-php-config=/usr/local/php/php74/7.4.0_1/bin/php-config
make && make install
cd ../