#!/bin/bash
#主要用于php版本之间的切换与安装

function php-iv {
  local PS_NAME="php-iv"
  local PS_VERSION="0.0.1"
  local PROGRAM_DISPLAY_VERSION="$PS_NAME v$PS_VERSION"
  local PHP_SWITCH_PATH="$PHP_IV_PATH"
  # colors
  COLOR_NORMAL=$(tput sgr0)
  COLOR_REVERSE=$(tput smso)
  
  # 默认第一次使用版本 入参
  local _VERSION=$2
  #php的安装路径
  local _PHP_PATH=""

  #将homebrew安装的php文件遍历读取
  if [[ -n $(command -v brew) ]]; then
    export _PHP_PATH="$_PHP_PATH $(echo $(find "" -maxdepth 1 -type d | grep -E 'php[0-9]*$'))"
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
    -h|--help|h|help|-u|--usage)
      echo $PROGRAM_DISPLAY_VERSION
      cat <<-USAGE

      相关指令信息:
        --help | -h | h | help     显示手册帮助信息
        --version | -v | v | version  显示脚本信息
        php-switch 显示已经安装同时待激活的版本

      切换版本(例):
        php-switch select 5          切换到PHP5.x最新一个版本
        php-switch select 5.5        切换到PHP5.5.x最后一个版本
        php-switch select 5.5.13     切换到PHP5.5.13

      安装版本：
        php-switch install php7  默认安装PHP7最新一个版本
        php-switch install php7.1  默认安装PHP7.1最新一个版本
        php-switch install php7.1.33 安装PHP7.1.33

      目前支持版本: 
              PHP5.5
              PHP5.6
              PHP7.1
              PHP7.2
              PHP7.3
              PHP7.4
			USAGE

      return 0
      ;;

    -v|--version|v|version)

      echo $PROGRAM_DISPLAY_VERSION

      return 0
      ;;
    install)
      case "$2" in
        php71|PHP71|PHP7.1|php7.1)
            cd ~
            cd $PHP_SWITCH_PATH
            source "php71.sh"
            return 0
        ;;

      esac
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
      php-switch --help >&2
      return 1
      ;;
  esac

  hash -r
}
