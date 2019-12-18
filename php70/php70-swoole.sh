#!/bin/bash
wget "https://pecl.php.net/get/swoole-2.0.7.tgz"
tar -zxvf "swoole-2.0.7.tgz"
cd swoole-2.0.7
phpize
./confiure
make && make install
cd $PHP_IV_PATH