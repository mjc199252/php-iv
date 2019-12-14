# php-iv
主要是用于linux以及mac端php版本安装与切换

### 支持使用平台

##### mac

##### ubuntu

##### centos

### 安装 使用教程

#### clone
ps:首先确认系统装有wget软件包

首先确保本地安装好git,然后执行命令
```
git clone https://github.com/mjc199252/php-iv.git
```
clone下来后进入文件目录，按下如下命令
```
pwd
查看当前路径
复制文件地址
执行如下命令
echo "export PHP_IV_PATH={刚才复制的地址}" >> ~/.bash_profile | export PHP_IV_PATH={刚才复制的地址}
```
而后执行
```
echo "source {刚才复制的地址}/php-iv.sh" >> ~/.bash_profile | source {刚才复制的地址}/php-iv.sh
```
