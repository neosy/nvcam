# Library for working with files
# Author: Neosy <neosy.dev@gmail.com>
#
#==================================
# Version 0.6
# 1) Fix error fs_name()
#==================================
# Version 0.5
# 1) Add function mount_check $1
#    $1 - path
#==================================
# Version 0.4
# 1) Add function fs_name $1
#    $1 - uuid disk
# 2) Exemple function diskSpace_check. Check disk space by uuid
#    diskSpace_check $(fs_name 2b025bf0-6148-4165-85c3-d0b07d977a2d) 5
#==================================
# Version 0.3
#==================================

source /usr/local/lib/sh_n/ntelegram_lib.sh

#BIN_PATH=$(dirname $(readlink -e $0))
HOST_NAME=`hostname | awk -F. '{print $1}'`

STORE_COUNT_DEFAULT=20

ARCHIVE_PATH=""
ARCHIVE_DATE=`date +'%Y-%m-%d'`
ARCHIVE_COUNT_DEFAULT=0
ARCHIVE_OWNER_DEFAULT="" #Example "neosy:neosy"
ARCHIVE_SHOW_ERROR=true

rm_store() {
    #Delete 10 files
    # rm_store "/path/file_*.*" 10
    #Delete 10 dirs
    # rm_store "/path/*/" 10 "-d"

    local pathFiles="$1"
    local last_store_cnt=$2
    local parm=$3 # example "-d"

    if [ -z $last_store_cnt ]; then
        last_store_cnt=$STORE_COUNT_DEFAULT
    fi

    if [ -z $parm ]; then
        parm=""
    fi

    ls ${parm} -1tr ${pathFiles} | head -n -${last_store_cnt} | xargs -d '\n' rm -rf --

    return 0
}

archive() {
    local source_path=$1
    local source_name=$2
    local archive_name=$3
    local archive_days_keep=$4
    local archive_owner=$5
    local show_error=$6

    local archive_file_name=""

    if [ -z ${ARCHIVE_PATH} ]; then
        echo "Error! The path {ARCHIVE_PATH} to the archives is not set."
        return 1
    fi

    if [ -z $archive_name ]; then
        archive_name=$source_name
    fi

    archive_file_name=${archive_name}_${ARCHIVE_DATE}.tar.gz

    if [ -z $archive_days_keep ]; then
        archive_days_keep=$ARCHIVE_COUNT_DEFAULT
    fi

    if [ -z ${archive_owner} ]; then
        archive_owner=$ARCHIVE_OWNER_DEFAULT;
    fi

    if [ -z ${show_error} ]; then
        show_error=$ARCHIVE_SHOW_ERROR
    fi

    if ! [ -d $ARCHIVE_PATH ]; then
        mkdir -p $ARCHIVE_PATH
        if [[ -n ${archive_owner} ]]; then
            chown ${archive_owner} $ARCHIVE_PATH
        fi
    fi

    echo -n "Archive ${archive_name}_${ARCHIVE_DATE}.tar.gz creating..."
    if [ $show_error == "true" ]; then
        cd $source_path && tar -czf $ARCHIVE_PATH/${archive_file_name} $source_name
    else
        cd $source_path && tar -czf $ARCHIVE_PATH/${archive_file_name} $source_name &>/dev/null
    fi
    echo " - OK"
    if [[ -n ${archive_owner} ]]; then
        chown ${archive_owner} $ARCHIVE_PATH/${archive_file_name}
    fi

    if [[ ${archive_days_keep}>0 ]]; then
        rm_store "$ARCHIVE_PATH/${archive_name}_*.*" ${archive_days_keep}
    fi

    return 0
}

diskSpace_check() {
    local fs_name=$1 #example VG_Backup-Backup
    local vlm_warning=$2 #volume in GB
    local message=""

    local block_size=1073741824 # =1GB

    local df_str=`df -l --block-size=$block_size | grep $fs_name`
    local vlm_total=`echo $df_str | awk '{print $2}'`
    local vlm_free=`echo $df_str | awk '{print $4}'`
    local vlm_dir_name=`echo $df_str | awk '{print $6}'`
    local vlm_free_percent=$( expr 100 - `echo $df_str | awk '{print $5}' | sed 's/%//'` )

    if [ $vlm_free -lt $vlm_warning ]; then
        message="Server name '${HOST_NAME}'"
        message="${message}%0AThe free disk space of '$fs_name'($vlm_dir_name) is ${vlm_free}GB (${vlm_free_percent}%). The total disk space is ${vlm_total}GB."
    fi

    if [ -n "$message" ]; then
        t_send-neosy "$message"
    fi
}

fs_name() {
    local uuid=$1 #example ad871e36-14ab-417f-9d8d-59c67a8ec051
    local blkid_path=`whereis blkid | awk '{print $2}'`

    local name=`$blkid_path | grep $uuid | awk '{print $1}' | sed 's/://'`
    if [ -z "$name" ]; then
      name=`ls -l /dev/disk/by-uuid | grep $uuid | awk '{print $NF}' | awk -F'/' '{print $NF}'`
      name="/dev/$name"
    fi

    echo $name
}


function line_parsing
{
    local separator=' '
    local line=$1
    local -n array=$2

    #Removing extra spaces
    line=`echo "$line" | tr -s " "`

    #Selection of parameters in "....."
    for param in `echo "$line" | grep -oP '".*?"'`
    do
        #Replacing spaces in the selected parameter with characters #sp;
        local paramN=`echo $param | sed 's/ /#sp;/g'`
        if [[ $param != $paramN ]]; then
            #In the parameter string, replacing parameters with space ".... ...". Convert "..... ......" to ".....#sp;....."
            line=`echo "$line" | sed 's/'${param}'/'${paramN}'/g'`
        fi
    done

    IFS=$separator read -r -a array <<< "$line"
    for index in "${!array[@]}"
    do
        array[index]=`echo "${array[index]}" | sed 's/#sp;/ /g' | sed 's/"//g'`
    done
}

function mount_check
{
    local path="$1"

    mountpoint -q "$path"

    return $?
}
