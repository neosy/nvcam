# Library for installing
# Author: Neosy <neosy.dev@gmail.com>
#
#==================================
# Version 0.2
#   1. Fix log_file_conf()
#==================================
# Version 0.1
#==================================

SOURCE_LIB_PATH=""
SOURCE_BIN_PATH=""
SOURCE_ETC_PATH=""
SOURCE_SERVICE_PATH=""

USR_LIB_PATH=/usr/local/lib
USR_BIN_PATH=/usr/local/bin
USR_ETC_PATH=/usr/local/etc
USR_SYSTEMD_PATH=/usr/lib/systemd/system

LIB_PATH=$USR_LIB_PATH/sh_n
BIN_PATH=$USR_BIN_PATH/sh_n
ETC_PATH=$USR_ETC_PATH
SERVICE_PATH=$USR_SYSTEMD_PATH

LOG_FILE_NAME=""
LOG_PATH=""
LOG_FILE=""

USER_GROUP="user:group"
USER=""
GROUP=""

function source_lib_path-set
{
    SOURCE_LIB_PATH="$1"
}

function source_bin_path-set
{
    SOURCE_BIN_PATH="$1"
}

function source_etc_path-set
{
    SOURCE_ETC_PATH="$1"
}

function source_service_path-set
{
    SOURCE_SERVICE_PATH="$1"
}

function check_root
{
    local isExit=${1:-true}
    local ret=1

    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        ret=0
        if [ $isExit ==  true ]; then
            exit 1
        fi
        return $ret
    fi

    return $ret
}

function log_file_conf
{
    LOG_PATH="$1"
    LOG_FILE_NAME="$2"
    if [ -n "$LOG_FILE_NAME" ]; then
        LOG_FILE="$LOG_PATH/$LOG_FILE_NAME"
    fi
}

function user_read
{
    local isExit=${1:-true}
    local ret=0 #0-SUCCESS 1-FAIL

    echo -n "Enter the user to start the service (Ex.: $USER_GROUP): "
    read USER_GROUP
    USER=`echo $USER_GROUP | awk -F':' '{print $1}'`
    GROUP=`echo $USER_GROUP | awk -F':' '{print $2}'`

    if ! id "$USER" >/dev/null 2>&1; then
        echo "User \"${USER}\" not found"
        ret=1
        if [ $isExit ==  true ]; then
            exit 1
        fi
        return $ret
    fi

    if ! (id -nG "$USER" | grep -qw "$GROUP"); then
        echo "The user \"$USER\" does not belong to the group \"$GROUP\""
        ret=1
        if [ $isExit ==  true ]; then
            exit 1
        fi
        return $ret
    fi

    return $ret
}

function copy_file
{
    local file_from=$1
    local path_to=$2
    local isExit=${3:-true}
    local ret=0 #0-SUCCESS 1-FAIL

    if [ ! -d "$path_to" ]; then
        mkdir "$path_to"
    fi

    if [ ! -d "$path_to" ]; then
        echo "Folder ${path_to} does not exist"
        ret=1
        if [ $isExit ==  true ]; then
            exit 1
        fi
        return $ret
    fi

    cp $file_from $path_to

    return $ret
}

function copy_lib
{
    local file_name=$1
    local rights="$2"
    local isOverwrite=${3:-true}

    if [ $isOverwrite == true ] || [ ! -f "$LIB_PATH/$file_name" ]; then
        copy_file $SOURCE_LIB_PATH/$file_name $LIB_PATH

        if [ -n "$rights" ]; then
            chmod $rights $LIB_PATH/$file_name
        fi
    fi
}

function copy_bin
{
    local file_name=$1
    local rights="$2"
    local isOverwrite=${3:-true}

    if [ $isOverwrite == true ] || [ ! -f "$BIN_PATH/$file_name" ]; then
        copy_file $SOURCE_BIN_PATH/$file_name $BIN_PATH

        if [ -n "$rights" ]; then
            chmod $rights $BIN_PATH/$file_name
        fi
    fi
}

function copy_etc
{
    local file_name=$1
    local rights="$2"
    local isOverwrite=${3:-false}
    local ret=1 #0-SUCCESS 1-FAIL

    if [ $isOverwrite == true ] || [ ! -f "$ETC_PATH/$file_name" ]; then
        copy_file $SOURCE_ETC_PATH/$file_name $ETC_PATH
        ret=0

        if [ -n "$rights" ]; then
            chmod $rights $ETC_PATH/$file_name
        fi
    fi

    return $ret
}

function copy_service
{
    local file_name=$1
    local rights="$2"
    local isOverwrite=${3:-false}
    local ret=1 #0-SUCCESS 1-FAIL

    if [ $isOverwrite == true ] || [ ! -f "$SERVICE_PATH/$file_name" ]; then
        copy_file $SOURCE_SERVICE_PATH/$file_name $SERVICE_PATH
        ret=0

        if [ -n "$rights" ]; then
            chmod $rights $SERVICE_PATH/$file_name
        fi
    fi

    return $ret
}
