#!/bin/bash
wget "https://pecl.php.net/get/redis-5.1.0.tgz"
tar -zxvf redis-5.1.0.tgz
cd "redis-5.1.0"
phpize
./configure
make && make install
cd ../
rm -rf redis-5.1.0.tgz redis-5.1.0