#!/bin/bash
### Simple utility to create logger for shell scripts

LOG_THRESHOLD=3
LOG_FILE=""
LOG_STDOUT=1
LOG_DATE_COMMAND="date +%Y%m%d_%H%M%S"

### hput and hget crerates something similar to hashmap (but only one instance, non iterable)
function hput
{
  eval hash"$1"='$2'
}

function hget 
{
  eval echo '${hash'"${1}"'#hash}'
}

### lpad pads given string to specified length adding spaces in the beginning of the string 
function lpad 
{
	word="${1}"
	length=${2}
	if [ "x${2}" = "x" ]
	then
		length=5
	fi
	while [ ${#word} -lt ${length} ]
	do
		word=" ${word}"
	done
	echo "${word}"
}

### lpad pads given string to specified length adding spaces at the end of the string
function rpad 
{
	word="${1}"
	length=$2
	if [ "x${2}" = "x" ]
	then
		length=5
	fi
	while [ ${#word} -lt 5 ]
	do
		word="${word} "
	done
	echo "${word}"
}

### define logging levels
hput DEBUG 1
hput INFO 2
hput WARN 3
hput ERROR 4
hput FATAL 5
hput ALL 6

### base logging function, used by other, level specific functions
function log
{
	lvl=`hget ${1}`
	if [ "${lvl}" -ge "${LOG_THRESHOLD}" ]
	then
		if [ "${LOG_STDOUT}" -eq "1" ] 
		then
			echo "`${LOG_DATE_COMMAND}` [ `rpad ${1}` ] ${2}" | tee -a ${LOG_FILE}
		else
			echo "`${LOG_DATE_COMMAND}` [ `rpad ${1}` ] ${2}" | tee -a ${LOG_FILE} >/dev/null 2>&1
		fi
	fi
}

### debug level
function log_debug
{
	log DEBUG "${1}"
}

### info level
function log_info
{
	log INFO "${1}"
}

### warn level
function log_warn
{
	log WARN "${1}"
}

### error level
function log_error
{
	log ERROR "${1}"
}

### fatal level
function log_fatal
{
	log FATAL "${1}"
}

### level all - higher then any other
function log_all
{
	log ALL "${1}"
}
