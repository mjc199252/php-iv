# php-iv

`php-iv` 是一个面向现代 macOS / Linux 的 PHP 源码安装与版本切换工具。

这个版本已经从“每个 PHP 版本一份安装脚本”的模式，重构成：

- shell bootstrap
- `bin/php-iv-core` 统一 CLI
- `lib/` 共享逻辑
- `manifests/php/*.sh` 版本清单
- `manifests/ext/*.sh` 扩展清单

## 当前阶段

Phase 1 已实现：

- 新的 bootstrap / core / manifest 架构
- 用户级安装目录，默认 `~/.php-iv`
- `install` / `select` / `list` / `doctor` / `info` / `env` / `ext list`
- `7.4` 与 `8.x` 的现代安装清单
- `5.5` 到 `7.3` 的 legacy manifest scaffolding

Legacy 版本目前会被识别和展示，但自动安装尚未启用。这样可以保留旧命令入口，同时把后续兼容工作隔离到 manifest 和 toolchain 层。

## 目录布局

默认安装根目录：

```bash
~/.php-iv
```

固定子目录：

```text
versions/
etc/
cache/
logs/
tmp/
src/
current -> 当前激活版本的软链
```

## 快速开始

先设置仓库路径：

```bash
export PHP_IV_PATH="/absolute/path/to/php-iv"
```

### Bash

把下面这行加入 `~/.bashrc` 或 `~/.bash_profile`：

```bash
source "$PHP_IV_PATH/php-iv.bash"
```

### Zsh

把下面这行加入 `~/.zshrc`：

```zsh
source "$PHP_IV_PATH/php-iv.zsh"
```

兼容旧用法时，Bash 也可以继续 source 顶层入口：

```bash
source "$PHP_IV_PATH/php-iv.sh"
```

## 常用命令

```bash
php-iv list --available
php-iv list --installed
php-iv doctor
php-iv doctor 8.4
php-iv info 8.4
php-iv install 8.4
php-iv install 8.4 redis
php-iv install --dry-run 8.4 redis
php-iv ext list 8.4
php-iv select 8.4
php-iv env 8.4
```

兼容旧命令格式：

```bash
php-iv install php7.4
php-iv install php7.1 redis
php-iv select 74
php-iv select 8
```

## 环境变量

- `PHP_IV_PATH`: bootstrap 使用的仓库根目录
- `PHP_IV_ROOT`: 安装根目录，默认 `~/.php-iv`
- `PHP_IV_CACHE_DIR`: 下载缓存目录，默认 `$PHP_IV_ROOT/cache`
- `PHP_IV_MAKE_JOBS`: `make -j` 并行数
- `PHP_IV_LOG_LEVEL`: `debug` / `info` / `warn` / `error`

## 支持矩阵

### PHP manifests

- `7.4`
- `8.0`
- `8.1`
- `8.2`
- `8.3`
- `8.4`

### Legacy manifests

- `5.5`
- `5.6`
- `7.0`
- `7.1`
- `7.2`
- `7.3`

### 扩展 manifests

- `redis`
- `yaf`
- `seaslog`
- `swoole`

不同扩展是否可用于某个 PHP 版本，由 manifest 兼容矩阵决定。`php-iv ext list <version>` 可以直接查看。

## 依赖

`php-iv doctor` 会给出当前平台的检查结果和安装建议。

常见依赖包括：

- 编译器工具链
- `autoconf`
- `pkg-config`
- `curl` 或 `wget`
- OpenSSL / libxml / sqlite / zlib 等开发头文件

macOS 通常使用 Homebrew，Linux 通常使用 `apt` 或 `dnf`。

## 开发与测试

运行本地检查：

```bash
./tests/run.sh
```

CI 会在 `ubuntu-latest` 和 `macos-latest` 上执行语法检查、bootstrap 检查和核心命令 smoke test。
