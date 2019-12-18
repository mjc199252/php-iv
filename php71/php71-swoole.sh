#!/bin/bash
wget "https://pecl.php.net/get/swoole-4.4.12.tgz"
tar -zxvf "swoole-4.4.12.tgz"
cd swoole-4.4.12
phpize
./confiure
make && make install
cd $PHP_IV_PATH