#!/bin/bash

#RETURN 0-SUCESS  1-FAIL

SCRIPT_PATH=$(dirname $(readlink -e $0))

source $SCRIPT_PATH/lib/nmpackage_lib.sh
source $SCRIPT_PATH/lib/ninstall_lib.sh

check_root

source_lib_path-set $SCRIPT_PATH/lib
source_bin_path-set $SCRIPT_PATH
source_etc_path-set $SCRIPT_PATH
source_service_path-set $SCRIPT_PATH

log_file_conf "/var/log/nvcam"

#******************************* Custom functions ********************************
function install_depends
{
    echo "Installing the required packages..."
    #app_install showmount nfs-common
    echo "Package installation is complete"
}

function install_lib
{
    copy_lib nfiles_lib.sh 644
}

function install_app
{
    copy_bin nvcam.sh 755
}

function install_config
{
    copy_etc nvcam.conf 644
}

function install_service
{
    copy_service nvcam.service 644
    if [ $? == 0 ]; then
        sed -i -E "s/(  User=.*)/  User=$USER/g" $SERVICE_PATH/nvcam.service
        sed -i -E "s/(  Group=.*)/  Group=$GROUP/g" $SERVICE_PATH/nvcam.service
    fi
}

function install_log
{
    mkdir -p $LOG_PATH
    chown $USER_GROUP $LOG_PATH
    chmod 750 $LOG_PATH
}

function main
{
    user_read

    install_depends
    install_lib
    install_app
    install_config
    install_service
    install_log
}

main

exit 0
