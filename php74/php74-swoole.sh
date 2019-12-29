#!/bin/bash
wget "https://pecl.php.net/get/swoole-4.4.12.tgz"
tar -zxvf "swoole-4.4.12.tgz"
cd swoole-4.4.12
phpize
./configure
make && make install
cd ../
rm -rf swoole-4.4.12 swoole-4.4.12.tgz