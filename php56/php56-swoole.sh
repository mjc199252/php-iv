#!/bin/bash
wget "https://pecl.php.net/get/swoole-1.8.11.tgz"
tar -zxvf "swoole-1.8.11.tgz"
cd swoole-1.8.11
phpize
./confiure
make && make install
cd $PHP_IV_PATH