#!/bin/bash
wget "https://pecl.php.net/get/yaf-2.3.3.tgz"
tar -zxvf "yaf-2.3.3.tgz"
cd yaf-2.3.3
phpize
./configure --with-php-config=/php-config