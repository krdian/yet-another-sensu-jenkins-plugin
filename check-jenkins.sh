#!/bin/bash

set -io pipefail

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2

REGEX_UUID="[[:alnum:]]{8}-[[:alnum:]]{4}-[[:alnum:]]{4}-[[:alnum:]]{4}-[[:alnum:]]{12}"
declare -A oversize
declare -A subdir_num

MAX_JOBS_SIZE=500
MAX_JOBS_NUMBER=100

STATUS="OK"

JENKINS_PATH="/var/lib/jenkins"
CHECK=""

# parse args
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -v|--version)
    VERSION="$2"
    shift; shift
    ;;
    -p|--path)
    JENKINS_PATH="$2"
    shift; shift
    ;;
    -c|--check)
    CHECK="$2"
    shift; shift
    ;;
    *)    # unknown option
    echo "Unknown option ${1}"
    exit
    ;;
  esac
done

if [[ ! -d  ${JENKINS_PATH}/jobs ]]; then 
  echo "No such directory ${JENKINS_PATH}/jobs"
  exit 1
fi

check_jobs_size() {
	## Check sub-directories size 
	ARR=$(echo $(du -sm ${JENKINS_PATH}/jobs/**/builds  | awk -v MAX_JOBS_SIZE="${MAX_JOBS_SIZE}" '$1 > MAX_JOBS_SIZE'| while read dir; do 
	  DIR_SIZE=$( echo $dir | cut -f1 -d' ' )
	  DIR=$( echo $dir | cut -f2 -d' ' )
	  DIR=${DIR%/*}
	  JOB=${DIR##*/}
	  echo [${JOB}]=${DIR_SIZE}MB
	done))

	eval "oversize+=($ARR)"

        if [[ ${#oversize[@]} > 0 ]]; then 
          STATUS="ERROR"
	  OUTPUT=$(for key in "${!oversize[@]}"; do echo $key:  ${oversize[$key]}; done)
        fi
}

check_jobs_numbers() {
	## Check number of sub-directiories  
	ARR=$(for i in $(find  ${JENKINS_PATH}/jobs/**/builds/ -maxdepth 0 -type d); do 

	  DIR=${i%/*/}
	  JOB=${DIR##*/}

	  cd $i
	  SUBDIRS=$(find . -type d -regex "\./[0-9]*" | wc -l | awk '$1 > ${MAX_JOBS_NUMBER}')
	  if [[ ${SUBDIRS} > 0 ]]; then
		echo [${JOB}]=${SUBDIRS}
	  fi
	done)

	eval "subdir_num=(${ARR})"

        if [[ ${#subdir_num[@]} > 0 ]]; then
          STATUS="ERROR"
	  OUTPUT=$(for key in "${!subdir_num[@]}"; do echo $key:  ${subdir_num[$key]}; done)
        fi

}

case ${CHECK} in 
  "jobs_size")
    check_jobs_size
    ;;
  "jobs_numbers")
    check_jobs_numbers
    ;;
esac


if [[ $STATUS == "OK" ]]; then
  echo "Status is ${STATUS}"
  exit 0
else
  echo "Status is ${STATUS}"
  echo "${OUTPUT}"
  exit 2
fi
