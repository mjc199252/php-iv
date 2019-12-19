# php-iv
主要是用于linux以及mac端php版本安装与切换
### 支持扩展
- [x] swoole
- [x] yaf
- [x] seaslog

### 注意事项
#### php7以下版本安装时会遇到bison version error 执行
```
cd ~
wget "http://ftp.gnu.org/gnu/bison/bison-2.4.1.tar.gz" 
tar -zxvf bison-2.4.1.tar.gz
cd bison-2.4.1
./configure
make 
make install
```
#### php7.0以上版本安装时遇到bison version error 执行
```
cd ~
wget "http://ftp.gnu.org/gnu/bison/bison-3.4.2.tar.gz" 
tar -zxvf bison-3.4.2.tar.gz
cd bison-3.4.2
./configure
make 
make install
```

### 支持使用平台

- [x] mac (已完成测试)

- [x] ubuntu (已完成测试)

- [ ] centos (测试中)

### 安装 使用教程

#### clone
ps:首先确认系统装有wget软件包，确保本地安装好git,然后执行命令

ps:首先确认系统装有wget软件包，确保本地安装好git,然后执行命令

ps:首先确认系统装有wget软件包，确保本地安装好git,然后执行命令

(emmm，三遍！)

```
git clone https://github.com/mjc199252/php-iv.git
```
clone下来后进入文件目录，按下如下命令
```
pwd
查看当前路径
复制文件路径
执行如下命令
echo 'export PHP_IV_PATH="{刚才复制的路径}"' >> ~/.bash_profile && export PHP_IV_PATH={刚才复制的路径}
```
而后执行
```
echo "source {刚才复制的路径}/php-iv.sh" >> ~/.bash_profile && source {刚才复制的路径}/php-iv.sh
source ~/.bash_profile
```
