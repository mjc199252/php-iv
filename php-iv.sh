#!/bin/bash
#主要用于php版本之间的切换与安装
function php-iv {
  local PS_NAME="php-iv"
  local PS_VERSION="0.0.4"
  local PROGRAM_DISPLAY_VERSION="$PS_NAME v$PS_VERSION"
  local PHP_SWITCH_PATH="$PHP_IV_PATH"
  # colors
  COLOR_NORMAL=$(tput sgr0)
  COLOR_REVERSE=$(tput smso)
  
  # 默认第一次使用版本 入参
  local _VERSION=$2
  #php的安装路径
  local _PHP_PATH=""

  local _EXTENSION=$3

  #将homebrew安装的php文件遍历读取
  if [[ -n $(command -v brew) ]]; then
    export _PHP_PATH="$_PHP_PATH $(echo $(find "/usr/local/php" -maxdepth 1 -type d | grep -E 'php[0-9]*$'))"
  fi

  # 如果有配置其他路径 则添加进来
  if [[ -n $PHP_PATH ]]; then
    export _PHP_PATH="$_PHP_PATH $PHP_PATH"
  fi

  # 循环将PHP安装地址放入
  PHPPATHS=() 
  for _PHP_PATH in $(echo $_PHP_PATH | tr " " "\n"); do
    PHPPATHS=("${PHPPATHS[@]}" $_PHP_PATH)
  done


  _PHP_PATH=

case "$1" in
    -h|--help|h|help)
          echo $PROGRAM_DISPLAY_VERSION
cat <<-EOF

        相关指令信息:
              --help | -h | h | help     显示手册帮助信息
              --version | -v | v | version  显示脚本信息
              php-iv 显示已经安装同时待激活的版本

        切换版本(例):
              php-iv select 5          切换到PHP5.x最新一个版本
              php-iv select 5.5        切换到PHP5.5.x最后一个版本
              php-iv select 5.5.13     切换到PHP5.5.13

        安装版本(例)：
              php-iv install php7.1  安装PHP7.1版本

        安装版本扩展(例)：
              php-iv install php7.1 seaslog 安装php7.1版本的seaslog
              php-iv install php7.1 yaf     安装php7.1版本的yaf
              php-iv install php7.1 swoole  安装php7.1版本的swoole

        目前支持版本:
              PHP5.5
              PHP5.6
              PHP7.1
              PHP7.2
              PHP7.3
              PHP7.4
              PS:7.4版本只支持部分功能

EOF
          return 0
          ;;
    -v|--version|v|version)
        echo $PROGRAM_DISPLAY_VERSION
        return 0 
        ;;
    install)
      case "$2" in
        php55|PHP55|PHP5.5|php5.5)
            cd "$PHP_SWITCH_PATH"

            cd "php55"

            if [[ ! -d "/usr/local/php/php55" ]]; then
                echo "开始安装$2" >&2
                source "php55.sh"
            else
                php-iv select 5.5
            fi

            case "$_EXTENSION" in
                seaslog)
                    source "php55-seaslog.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/5.5/php.ini 中"
                    return 0
                ;;
                swoole)
                    source "php55-swoole.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/5.5/php.ini 中"
                    return 0
                ;;
                yaf)
                    source "php55-yaf.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/5.5/php.ini 中"
                    return 0
                ;;
                "")
                    return 0
                ;;    
                *)
                    echo "对不起, 没有在找到$2版本关于$3扩展安装信息" >&2
                    return 0
                ;;
            esac

            return 0
            ;;
        php56|PHP56|PHP5.6|php5.6)
            cd $PHP_SWITCH_PATH
            cd "php56"


            if [[ ! -d "/usr/local/php/php56" ]]; then
                echo "开始安装$2" >&2
                source "php56.sh"
            else
                php-iv select 5.6
            fi

            case "$_EXTENSION" in
                seaslog)
                    source "php56-seaslog.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/5.6/php.ini 中"
                    return 0
                ;;
                swoole)
                    source "php56-swoole.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/5.6/php.ini 中"
                    return 0
                ;;
                yaf)
                    source "php56-yaf.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/5.6/php.ini 中"
                    return 0
                ;;
                "")
                    return 0
                ;;
                *)
                    echo "对不起, 没有在找到$2版本关于$3扩展安装信息" >&2
                    return 0
                ;;
            esac

            return 0
            ;;
        php70|PHP70|PHP7.0|php7.0)
            cd $PHP_SWITCH_PATH
            cd "php70"


            if [[ ! -d "/usr/local/php/php70" ]]; then
                echo "开始安装$2" >&2
                source "php70.sh"
            else
                php-iv select 7。0
            fi

            case "$_EXTENSION" in
                seaslog)
                    source "php70-seaslog.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.0/php.ini 中"
                    return 0
                ;;
                swoole)
                    source "php70-swoole.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.0/php.ini 中"
                    return 0
                ;;
                yaf)
                    source "php70-yaf.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.0/php.ini 中"
                    return 0
                ;;
                "")
                    return 0
                ;;
                *)
                    echo "对不起, 没有在找到$2版本关于$3扩展安装信息" >&2
                    return 0
                ;;
            esac

            return 0
            ;;
        php71|PHP71|PHP7.1|php7.1)
            cd $PHP_SWITCH_PATH
            cd "php71"
            if [[ ! -d "/usr/local/php/php71" ]]; then
                echo "开始安装$2" >&2
                source "php71.sh"
            else
                php-iv select 7.1
            fi

            case "$_EXTENSION" in
                seaslog)
                    source "php71-seaslog.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.1/php.ini 中"
                    return 0
                ;;
                swoole)
                    source "php71-swoole.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.1/php.ini 中"
                    return 0
                ;;
                yaf)
                    source "php71-yaf.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.1/php.ini 中"
                    return 0
                ;;
                "")
                    return 0
                ;;
                *)
                    echo "对不起, 没有在找到$2版本关于$3扩展安装信息" >&2
                    return 0
                ;;
            esac
            return 0
            ;;
        php72|PHP72|PHP7.2|php7.2)
            cd $PHP_SWITCH_PATH
            cd "php72"
            if [[ ! -d "/usr/local/php/php72" ]]; then
                echo "开始安装$2" >&2
                source "php72.sh"
            else
                php-iv select 7.2
                php -v
            fi

            case "$_EXTENSION" in
                seaslog)
                    source "php72-seaslog.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.2/php.ini 中"
                    return 0
                ;;
                swoole)
                    source "php72-swoole.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.2/php.ini 中"
                    return 0
                ;;
                yaf)
                    source "php72-yaf.sh"
                    echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.2/php.ini 中"
                    return 0
                ;;
                "")
                    return 0
                ;;
                *)
                    echo "对不起, 没有在找到$2版本关于$3扩展安装信息" >&2
                    return 0
                ;;
            esac
            return 0
            ;;
        php73|PHP73|PHP7.3|php7.3)
            cd $PHP_SWITCH_PATH
            cd "php73"
            if [[ ! -d "/usr/local/php/php73" ]]; then
                echo "开始安装$2" >&2
                source "php73.sh"
            else
                php-iv select 7.3
                php -v
            fi

                case "$_EXTENSION" in
                    seaslog)
                        source "php73-seaslog.sh"
                        echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.3/php.ini 中"
                        return 0
                    ;;
                    swoole)
                        source "php73-swoole.sh"
                        echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.3/php.ini 中"
                        return 0
                    ;;
                    yaf)
                        source "php73-yaf.sh"
                        echo "请把扩展安装路径放入 /usr/local/phpconf/php/7.3/php.ini 中"
                        return 0
                    ;;
                    "")
                    return 0
                    ;;
                    *)
                        echo "对不起, 没有在找到$2版本关于$3扩展安装信息" >&2
                        return 0
                    ;;
                esac
            return 0
            ;;
        php74|PHP74|PHP7.4|php7.4)
            cd $PHP_SWITCH_PATH
            cd "php74"

            if [[ ! -d "/usr/local/php/php74" ]]; then
                echo "开始安装$2" >&2
                source "php74.sh"
            else
                php-iv select 7.4
                php -v
            fi

                case "$_EXTENSION" in
                    "")
                      return 0
                    ;;
                    *)
                        echo "对不起, 没有在找到$2版本关于$3扩展安装信息" >&2
                        return 0
                    ;;
                esac
            return 0
            ;;
        *)
            echo "对不起, 没有在找到关于$2的相关版本安装信息" >&2
            return 0
            ;;
      esac
      cd "$PHP_SWITCH_PATH"
      return 0
      ;;  
    "")
      if [ ${#PHPPATHS[@]} -eq 0 ]; then
        echo '对不起，没有获取到已经安装的PHP版本' >&2
        return 1
      fi
      _PHP_PATH=()
      for _PHP_REPOSITORY in "${PHPPATHS[@]}"; do
        for _dir in $(find $(echo $_PHP_REPOSITORY) -maxdepth 1 -mindepth 1 -type d 2>/dev/null); do
          _PHP_PATH=("${_PHP_PATH[@]}" "$($_dir/bin/php-config --version 2>/dev/null)")
        done
      done

      _PHP_PATH=$(IFS=$'\n'; echo "${_PHP_PATH[*]}" | sort -r -t . -k 1,1n -k 2,2n -k 3,3n)

      for version in $(echo $_PHP_PATH | tr " " "\n"); do
        local selected=" "
        local color=$COLOR_NORMAL

        if [[ "$version" == "$(php-config --version 2>/dev/null)" ]]; then
          local selected="->"
          local color=$COLOR_REVERSE
        fi

        printf "${color}%s %s${COLOR_NORMAL}\n" "$selected" "$version"
      done

      return 0
      ;;
    select)
      #查看版本地址切换路径是否存在
      for PHP_KEY in "${PHPPATHS[@]}"; do
        if [[ -d "$PHP_KEY/$_VERSION" && -z $_PHP_ROOT ]]; then
          local _PHP_ROOT=$PHP_KEY/$_VERSION
          break;
        fi
      done
      #处理PHP执行地址   
      if [[ -z $_PHP_ROOT ]]; then
        _VERSION_FUZZY=()
        for PHP_PATH_KEY in "${PHPPATHS[@]}"; do
          for _dir in $(find $PHP_PATH_KEY -maxdepth 1 -mindepth 1 -type d 2>/dev/null); do
            _VERSION_FUZZY=("${_VERSION_FUZZY[@]}" "$($_dir/bin/php-config --version 2>/dev/null)")
          done
        done

        _VERSION_FUZZY=$(IFS=$'\n'; echo "${_VERSION_FUZZY[*]}" | sort -r -t . -k 1,1n -k 2,2n -k 3,3n | grep -E "^$_VERSION" 2>/dev/null | tail -1)

        for PHP_PATH_KEY in "${PHPPATHS[@]}"; do
          for _dir in $(find $PHP_PATH_KEY -maxdepth 1 -mindepth 1 -type d 2>/dev/null); do
            _PHP_VERSION="$($_dir/bin/php-config --version 2>/dev/null)"
            if [[ -n "$_VERSION_FUZZY" && "$_PHP_VERSION" == "$_VERSION_FUZZY" ]]; then
              local _PHP_ROOT=$_dir
              break;
            fi
          done
        done
      fi
      #没有找到版本信息的报错
      if [[ -z $_PHP_ROOT ]]; then
        echo "对不起, 没有在$PS_NAME中找到关于$1的相关版本信息" >&2
        return 1
      fi
      #直接获取文件信息
      export PHPRC=""
      [[ -f $_PHP_ROOT/etc/php.ini ]] && export PHPRC=$_PHP_ROOT/etc/php.ini
      [[ -d $_PHP_ROOT/bin  ]]        && export PATH="$_PHP_ROOT/bin:$PATH"
      [[ -d $_PHP_ROOT/sbin ]]        && export PATH="$_PHP_ROOT/sbin:$PATH"

      #配置$_PHP_ROOT/share/man地址
      local _MANPATH=$(php-config --man-dir)
      [[ -z $_MANPATH ]] && _MANPATH=$_PHP_ROOT/share/man
      [[ -d $_MANPATH ]] && export MANPATH="$_MANPATH:$MANPATH"
      return 0
      ;;  
    *)
      php-iv --help >&2
      return 1
      ;;
  esac

  hash -r
}
