#!/bin/bash
wget "https://pecl.php.net/get/yaf-2.3.3.tgz"
tar -zxvf "yaf-2.3.3.tgz"
cd yaf-2.3.3
phpize
./configure --with-php-config=/usr/local/php/php55/5.5.38_1/bin/php-config
make && make install
cd ../
rm -rf yaf-2.3.3 yaf-2.3.3.tgz