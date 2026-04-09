# php-iv

`php-iv` 是一个面向 macOS 与 Linux 的 PHP 源码安装与版本切换工具，用于在同一台机器上管理多个 PHP 版本，并为不同版本安装匹配的扩展。

项目的核心思路不是直接依赖系统级 PHP 目录，而是在用户目录下维护一套独立的 PHP 安装体系。这样可以降低系统环境污染，便于开发、调试、兼容性验证和多版本切换。

## 功能概览

- 按版本安装 PHP
- 管理本地已安装的多个 PHP 版本
- 在当前 shell 会话中切换激活版本
- 为指定 PHP 版本安装扩展
- 检查构建依赖和平台条件
- 为 legacy 版本自动拉起隔离的兼容 toolchain

## 架构说明

当前版本采用 manifest 驱动的实现方式，核心组成如下：

- `php-iv.bash` / `php-iv.zsh`：shell bootstrap，负责把 `php-iv` 命令接入当前 shell
- `bin/php-iv-core`：统一 CLI 入口
- `lib/`：安装、诊断、环境导出、平台适配等共享逻辑
- `manifests/php/`：PHP 版本元数据
- `manifests/ext/`：扩展兼容矩阵
- `manifests/toolchain/`：legacy PHP 所需的旧版 OpenSSL / Autoconf / Bison 等工具链定义

## 安装方式

### 1. 克隆仓库

```bash
git clone https://github.com/mjc199252/php-iv.git
cd php-iv
```

### 2. 配置仓库路径

```bash
export PHP_IV_PATH="$(pwd)"
```

如果希望长期使用，建议把它写入 shell 配置文件。

### 3. 加载 bootstrap

#### Bash

将下面内容写入 `~/.bashrc` 或 `~/.bash_profile`：

```bash
export PHP_IV_PATH="/absolute/path/to/php-iv"
source "$PHP_IV_PATH/php-iv.bash"
```

#### Zsh

将下面内容写入 `~/.zshrc`：

```zsh
export PHP_IV_PATH="/absolute/path/to/php-iv"
source "$PHP_IV_PATH/php-iv.zsh"
```

#### 兼容入口

如果你仍希望沿用旧入口，Bash 下也可以这样加载：

```bash
source "$PHP_IV_PATH/php-iv.sh"
```

### 4. 重新加载 shell 配置

```bash
source ~/.bashrc
```

或：

```zsh
source ~/.zshrc
```

## 默认目录布局

默认安装根目录为：

```bash
~/.php-iv
```

目录结构如下：

```text
~/.php-iv/
├── versions/    # 各 PHP 版本安装目录
├── etc/         # 各版本配置文件
├── cache/       # 下载缓存
├── logs/        # 构建日志
├── tmp/         # 临时构建目录
├── src/         # 预留源码目录
├── toolchains/  # legacy 版本使用的隔离 toolchain
└── current      # 当前激活版本的软链
```

## 环境变量

`php-iv` 当前使用以下环境变量：

- `PHP_IV_PATH`：仓库根目录，bootstrap 和 core CLI 都会使用它
- `PHP_IV_ROOT`：安装根目录，默认值为 `~/.php-iv`
- `PHP_IV_CACHE_DIR`：下载缓存目录，默认值为 `$PHP_IV_ROOT/cache`
- `PHP_IV_MAKE_JOBS`：编译并行数，对应 `make -j`
- `PHP_IV_LOG_LEVEL`：日志级别，可选 `debug`、`info`、`warn`、`error`

示例：

```bash
export PHP_IV_ROOT="$HOME/.local/php-iv"
export PHP_IV_MAKE_JOBS="8"
export PHP_IV_LOG_LEVEL="debug"
```

## 依赖说明

安装 PHP 前，建议先运行：

```bash
php-iv doctor
```

现代 PHP 常见依赖包括：

- 编译器工具链
- `autoconf`
- `pkg-config`
- `curl` 或 `wget`
- OpenSSL / libxml / sqlite / zlib 等开发头文件

legacy PHP 在首次安装时，还可能由 `php-iv` 自动准备这些用户级 toolchain：

- `openssl-1.0.2u`
- `openssl-1.1.1w`
- `autoconf-2.69`
- `bison-2.7.1`
- `bison-3.8.2`

## 支持矩阵

### 当前支持的 PHP 主线版本

- `7.4`
- `8.0`
- `8.1`
- `8.2`
- `8.3`
- `8.4`

### 当前支持的 legacy 版本

- `5.5`
- `5.6`
- `7.0`
- `7.1`
- `7.2`
- `7.3`

### 当前支持的扩展

- `redis`
- `yaf`
- `seaslog`
- `swoole`

不同扩展会根据目标 PHP 版本自动选择匹配的 PECL 发行版，而不是固定使用同一个扩展版本。

## 常用命令

### 查看帮助

```bash
php-iv help
php-iv --help
```

### 查看可安装版本

```bash
php-iv list --available
```

### 查看本地已安装版本

```bash
php-iv list --installed
```

### 检查环境

```bash
php-iv doctor
php-iv doctor 8.4
php-iv doctor 7.1
```

### 查看版本信息

```bash
php-iv info 8.4
php-iv info 7.1
```

### 安装 PHP

```bash
php-iv install 8.4
php-iv install 8.3
php-iv install 7.4
php-iv install 7.1
php-iv install 5.6
```

### 安装 PHP 并同时安装扩展

```bash
php-iv install 8.4 redis
php-iv install 8.4 swoole
php-iv install 7.4 redis
php-iv install 7.1 yaf
php-iv install 5.6 seaslog
```

### 仅做安装前检查，不真正执行构建

```bash
php-iv install --dry-run 8.4 redis
php-iv install --dry-run 7.1 redis
php-iv install --dry-run 5.6 yaf
```

### 查看某个 PHP 版本可安装的扩展

```bash
php-iv ext list 8.4
php-iv ext list 7.4
php-iv ext list 5.6
```

### 切换当前 shell 的 PHP 版本

```bash
php-iv select 8.4
php-iv select 7.4
php-iv select 7.1
```

`select` 依赖 bootstrap。也就是说，你必须先 `source php-iv.bash` 或 `source php-iv.zsh`，它才能修改当前 shell 的 `PATH`、`PHPRC` 和 `MANPATH`。

### 输出某个已安装版本的环境变量

```bash
php-iv env 8.4
php-iv env 7.4
```

这个命令主要供 bootstrap 使用，也可以用于排查当前版本切换的环境变量内容。

## 兼容旧命令格式

为了兼容旧用法，以下形式仍然可用：

```bash
php-iv install php7.4
php-iv install php7.1 redis
php-iv install php56 yaf
php-iv select 74
php-iv select 71
php-iv select 8
```

## 操作说明

### 安装一个现代 PHP 版本

典型流程如下：

1. 运行 `php-iv doctor 8.4` 检查依赖
2. 执行 `php-iv install 8.4`
3. 如需扩展，执行 `php-iv install 8.4 redis`
4. 执行 `php-iv select 8.4`
5. 用 `php -v` 和 `php --ini` 验证当前环境

示例：

```bash
php-iv doctor 8.4
php-iv install 8.4
php-iv install 8.4 redis
php-iv select 8.4
php -v
php --ini
```

### 安装一个 legacy PHP 版本

legacy 版本的流程基本一致，但首次安装时可能会额外准备隔离 toolchain，因此耗时通常更长。

示例：

```bash
php-iv doctor 7.1
php-iv install --dry-run 7.1 redis
php-iv install 7.1
php-iv install 7.1 redis
php-iv select 7.1
php -v
```

### 为已安装版本补装扩展

如果某个 PHP 版本已经安装完成，可以直接再次调用 `install` 并传入扩展名：

```bash
php-iv install 8.4 redis
php-iv install 8.4 swoole
php-iv install 7.4 yaf
```

### 查看当前可切换版本

```bash
php-iv list --installed
```

当前激活版本会在输出中以标记形式显示。

## 平台与兼容性说明

- modern 版本优先面向现代 macOS 和 Linux
- legacy 版本使用隔离 toolchain 处理历史依赖
- `macos-arm64` 上的旧版 PHP 会明确标记为 experimental
- experimental 不表示命令不可执行，而是表示成功率和稳定性低于主线支持平台

## 故障排查

### `php-iv select` 无效

通常是因为当前 shell 没有 source bootstrap。请确认已加载：

```bash
source "$PHP_IV_PATH/php-iv.bash"
```

或：

```zsh
source "$PHP_IV_PATH/php-iv.zsh"
```

### 安装失败

安装失败时可查看构建日志目录：

```bash
ls ~/.php-iv/logs
```

也可以先使用 dry-run 模式确认版本、扩展、toolchain 和平台判断是否符合预期：

```bash
php-iv install --dry-run 7.1 redis
```

### 需要确认某个版本的支持状态

```bash
php-iv info 7.1
php-iv info 8.4
```

## 开发与测试

仓库内置测试脚本：

```bash
./tests/run.sh
```

CI 会在 `ubuntu-latest` 和 `macos-latest` 上执行语法检查、bootstrap 检查和核心命令 smoke test。
