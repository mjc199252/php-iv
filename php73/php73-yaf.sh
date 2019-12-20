#!/bin/bash
wget "https://pecl.php.net/get/yaf-3.0.8.tgz"
tar -zxvf "yaf-3.0.8.tgz"
cd yaf-3.0.8
phpize
./configure --with-php-config=/usr/local/php/php73/7.3.12_1/bin/php-config
make && make install
cd ../