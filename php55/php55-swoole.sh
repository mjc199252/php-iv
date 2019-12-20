#!/bin/bash
wget "https://pecl.php.net/get/swoole-1.7.6.tgz"
tar -zxvf "swoole-1.7.6.tgz"
cd swoole-1.7.6
phpize
./configure
make && make install
cd ../