#!/bin/bash
wget "https://pecl.php.net/get/SeasLog-2.0.2.tgz"
tar -zxvf SeasLog-2.0.2.tgz
cd "SeasLog-2.0.2"
phpize
./configure
make && make install
cd ../
rm -rf SeasLog-2.0.2 SeasLog-2.0.2.tgz