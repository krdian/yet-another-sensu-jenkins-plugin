#!/bin/bas                                                                                                                                                                    
set -io pipefail

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2

REGEX_UUID="[[:alnum:]]{8}-[[:alnum:]]{4}-[[:alnum:]]{4}-[[:alnum:]]{4}-[[:alnum:]]{12}"
declare -A oversize
declare -A subdir_num

## Check sub-directories size
ARR=$(echo $(du -sm /var/lib/jenkins/jobs/**/builds  | awk '$1 > 500'| while read dir; do
  DIR_SIZE=$( echo $dir | cut -f1 -d' ' )
  DIR=$( echo $dir | cut -f2 -d' ' )
  DIR=${DIR%/*}
  JOB=${DIR##*/}
  echo [${JOB}]=${DIR_SIZE}MB
done))
eval "oversize+=($ARR)"


for key in "${!oversize[@]}"; do echo $key:  ${oversize[$key]}; done


## Check number of sub-directiories
ARR=$(for i in $(find  /var/lib/jenkins/jobs/**/builds/ -maxdepth 0 -type d); do

  DIR=${i%/*/}
  JOB=${DIR##*/}

  cd $i
  SUBDIRS=$(find . -type d -regex "\./[0-9]*" | wc -l | awk '$1 > 100')
  if [[ ${SUBDIRS} > 0 ]]; then
        echo [${JOB}]=${SUBDIRS}
  fi
done)

eval "subdir_num=(${ARR})"

for key in "${!subdir_num[@]}"; do echo $key:  ${subdir_num[$key]}; done

STATUS="OK"

if [[ $STATUS == "OK" ]]; then
  echo "Order status is ${STATUS}"
  exit 0
else
  echo "Order status is ${STATUS}"
  echo "${RESPONSE_2}"
  exit 2
fi
