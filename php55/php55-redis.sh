#!/bin/bash
wget "https://pecl.php.net/get/redis-3.1.4.tgz"
tar -zxvf redis-3.1.4.tgz
cd "redis-3.1.4"
phpize
./configure
make && make install
cd ../
rm -rf redis-3.1.4.tgz redis-3.1.4