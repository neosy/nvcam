#!/bin/bash
# Recording from an IP camera
# Author: Neosy <neosy.dev@gmail.com>
#
#==================================
# Version 0.2
#   1. Added config file
#==================================
# Version 0.1
#   1. Clear log
#==================================

source /usr/local/lib/sh_n/nfiles_lib.sh

CONF_FILE_NAME=nvcam.conf
CONF_FILE=/usr/local/etc/$CONF_FILE_NAME

VIDEO_CAMERA_NAME=""
VIDEO_SRC=""
VIDEO_DST=""
VIDEO_STORE_SIZE=100 #MByte
VIDEO_TLN=60 # Time len
VIDEO_CODEC="" #copy mpeg4 h264 h265 #libx264
VIDEO_QUALITY="" #-b:v 4096k -q:v 10   #-q:v 10   1-high     #-preset fast -crf 0
AUDIO_CODEC=""
SERVICE_DURATION_TIME="" # -t 01:00:00"
OUTPUT_FILE_NAME=""
LOG_PATH=""
LOG_STORE_COUNT=3

. $CONF_FILE

OUTPUT_DIR="$VIDEO_CAMERA_NAME"

mkdir -p $LOG_PATH

WHILE_DELAY=5

clearSaveStore() {
    store_path=$1
    store_size=$2

    volumeSize=$(du -sb $store_path | awk {'print $1'})
    volumeSize=$(( ${volumeSize}/1024/1024 ))
    volumeSize_left=0

    if [ ${volumeSize} -gt ${store_size} ]; then
        volumeSize_left=$(( $volumeSize - $store_size ))
    else
        return
    fi

    cd $store_path
    mth_dir_array=($(ls))

    for mth_dir in ${mth_dir_array[@]}; do
        date_dir_array=($(cd $mth_dir && ls))

        for date_dir in ${date_dir_array[@]}; do
            hour_dir_array=($(cd $mth_dir/$date_dir && ls))

            for hour_dir in ${hour_dir_array[@]}; do

                hour_dir_size=$(du -sb $mth_dir/$date_dir/$hour_dir | awk {'print $1'})
                hour_dir_size=$(( $hour_dir_size/1024/1024 ))

                rm -R $mth_dir/$date_dir/$hour_dir
                volumeSize_left=$(( volumeSize_left-$hour_dir_size ))

                if [ $volumeSize_left -le 0 ]; then
                    return
                fi
            done
            rm -R $mth_dir/$date_dir
        done
        rm -R $mth_dir
    done
}

#=================== Begin program =======================

trap 'echo Stop program...; exit' INT

if ! [ -d ${VIDEO_DST}/${OUTPUT_DIR} ]; then
    mkdir -p ${VIDEO_DST}/${OUTPUT_DIR}
fi

while [ true ]
do
    clearSaveStore ${VIDEO_DST}/${OUTPUT_DIR} ${VIDEO_STORE_SIZE}

    OUTPUT_PATH=${VIDEO_DST}

    YEAR_MONTH_NOW=`date +'%Y-%m'`
    DATE_NOW=`date +'%Y-%m-%d'`
    HOUR_NOW=`date +'%H'`

    LOG_FILEPATH="$LOG_PATH"
    LOG_FILENAME="ffmpeg_$BewardN500_`date +'%Y-%m-%d'`.log"

    if [ -n $OUTPUT_DIR ]; then
        if ! [ -d $VIDEO_DST/$OUTPUT_DIR ]; then
            cd $VIDEO_DST && mkdir $OUTPUT_DIR
        fi
        OUTPUT_PATH=$VIDEO_DST/$OUTPUT_DIR
    fi

    if ! [ -d $OUTPUT_PATH/$YEAR_MONTH_NOW/$DATE_NOW/$HOUR_NOW ]; then
        cd $OUTPUT_PATH && mkdir -p $YEAR_MONTH_NOW/$DATE_NOW/$HOUR_NOW
    fi
    OUTPUT_PATH=$OUTPUT_PATH/$YEAR_MONTH_NOW/$DATE_NOW/$HOUR_NOW

    if ! [ -d $LOG_FILEPATH/$YEAR_MONTH_NOW ]; then
        cd $LOG_FILEPATH && mkdir -p $YEAR_MONTH_NOW
    fi
    rm_store "$LOG_FILEPATH/*/" $LOG_STORE_COUNT "-d"
    LOG_FILEPATH=$LOG_FILEPATH/$YEAR_MONTH_NOW

    cd ${OUTPUT_PATH} && ffmpeg -rtsp_transport tcp -i $VIDEO_SRC $VIDEO_CODEC $VIDEO_QUALITY $AUDIO_CODEC $SERVICE_DURATION_TIME -map 0 -f segment -segment_time $VIDEO_TLN -reset_timestamps 1 -strftime 1 "${OUTPUT_FILE_NAME}" &>>${LOG_FILEPATH}/$LOG_FILENAME
    sleep $WHILE_DELAY
done
