#!/bin/bash
# <bitbar.title>Tracker Madafaker</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>mnlg_</bitbar.author>
# <bitbar.author.github>mnlg</bitbar.author.github>
# <bitbar.desc>A fuking simple and minimalistic time tracker.</bitbar.desc>
# <bitbar.image>http://i.imgur.com/Tee97hU.png</bitbar.image>
# <bitbar.dependencies>bash</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/mnlg</bitbar.abouturl>

DATAFOLDER=~/.trackermadafaker
LOGFILE=${DATAFOLDER}/.timetable
PROJECTSFILE=${DATAFOLDER}/projects.txt
TIMESTAMP=$(date +%s)
KEEPALIVEFILE=${DATAFOLDER}/.keepalive
CURRENTFILE=${DATAFOLDER}/.current
OPEN=/usr/bin/open 

#####################
### INITIALIZE PLUGIN
#####################

if [ ! -d $DATAFOLDER ]; then
    mkdir $DATAFOLDER
    echo ${TIMESTAMP} > $KEEPALIVEFILE
    touch $LOGFILE
    touch $PROJECTSFILE
    touch $CURRENTFILE
fi

CURRENT="$(cat $CURRENTFILE)"
KEEPALIVE="$(cat $KEEPALIVEFILE)"

if [ ${KEEPALIVE} -lt $(( ${TIMESTAMP}-600 )) ]; then
    if [ "$1" = "stop" ]; then 
        TIMESTAMP="${KEEPALIVE}"
    else
        $0 stop
        CURRENT=""
    fi
fi

if [ "${TIMESTAMP}" != "${KEEPALIVE}" ]; then
    echo $TIMESTAMP > $KEEPALIVEFILE
fi

IFS="|" read -ra P <<< "$( awk '$1=$1' ORS='|' $PROJECTSFILE )"
IFS="|" read -ra D <<< "$( awk '$1=$1' ORS='|' $LOGFILE )"

##################
### PLUGIN OPTIONS
##################

case $1 in
    start )
        $0 stop
        echo $2 > $CURRENTFILE
        echo "start;${2};${TIMESTAMP}" >> $LOGFILE
        ;;
    stop )
        if [ "${CURRENT}" != "" ]; then
            echo "stop;${CURRENT};${TIMESTAMP}" >> $LOGFILE
        fi
        echo "" > $CURRENTFILE
        ;;
    reset )
        $0 stop
        echo "" > $LOGFILE
        ;;
esac

if [ "$1" != "" ]; then exit 0; fi

######################
### RENDER BITBAR MENU
######################

ICON=":rage:"
MAIN="Yo bitch!"
SEPARATOR=" |size=10"

if [ "${CURRENT}" != "" ]; then
    ICON=":sunglasses:"
    MAIN="~ ${CURRENT} ~"
fi

echo "${ICON} ${MAIN} "
echo "---"

for ((i = 0; i < ${#P[@]}; i++))
do
    item="${P[$i]}"
    STATUS="start"
    START=0
    TOTALTIME=0
    PROGRESS="| color=#7d7d7d size=10" 

    if [ "${CURRENT}" = "$item" ]; then
        STATUS="stop"
        PROGRESS="» In progress... | color=#2ECC71 size=12"
    fi
 
    for ((n=0; n < ${#D[@]}; n++))
    do
        data="${D[$n]}"
        IFS=';' read -ra E <<< "${data}"
        if [ "${E[1]}" = "${item}" ]; then
            case "${E[0]}" in
                start ) 
                    START=${E[2]}
                    ;;
                stop ) 
                    TOTALTIME=$(( ${TOTALTIME}+(${E[2]}-${START}) )) 
                    START=0
                    ;;
            esac
        fi
    done

    if [ ${START} != 0 ]; then
        TOTALTIME=$(( ${TOTALTIME}+(${TIMESTAMP}-${START}) ))
    fi
 
    printf -v HOURS "%02g" $(( ${TOTALTIME}/3600 ))
    printf -v MINS "%02g" $(( (${TOTALTIME}%3600)/60 ))
    echo $SEPARATOR
    echo "$item | bash=$0 param1=$STATUS param2='${item}' refresh=true terminal=false"
    echo "${HOURS}:${MINS} ${PROGRESS}"
done

echo $SEPARATOR
echo "---"
echo "Options"
echo "-- Edit projects file | bash=${OPEN} param1=${PROJECTSFILE} terminal=false"
echo "-----"
echo "-- Reload plugin | refresh=true"
echo "-- Stop tracking | bash=$0 param1=stop refresh=true terminal=false"
echo "-----"
echo "-- Reset time tracker | bash=$0 param1=reset terminal=false refresh=true color=#FA5C4F"
