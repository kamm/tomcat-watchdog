#!/bin/bash

. /home/tomcat/tomcat_watchdog/lib/bashlogging.sh
. /home/tomcat/.bash_profile

###CONFIGURATION
#path to java directory - without this tomcat cannot be started
JAVA_HOME=/usr/java/jdk1.6.0_22/
#path to tomcat directory - where is located directory bin
TOMCAT_HOME="/opt/tomcat"
TOMCAT_STARTUP_SCRIPT=${TOMCAT_HOME}/bin/startup.sh
TOMCAT_SHUTDOWN_SCRIPT=${TOMCAT_HOME}/bin/shutdown.sh
#logging to stdout disabled - only to file
LOG_STDOUT=0
#threshold for logger - level warn and higher
LOG_THRESHOLD=3
#path to log file
LOG_FILE="/home/tomcat/tomcat_watchdog/logs/tomcat_watchdog.log"
###END CONFIGRATION

function check_for_pid 
{ 
	ps auxwww | awk '$2=="'${1}'"{print $2}' | wc -l
}

function find_tomcat_pid
{
	tomcat_pid=`ps auxwww | grep java | grep -v grep | grep tomcat | grep catalina | awk '{print $2}'`
	echo "${tomcat_pid}"
}

function log_rotate
{
	date_rotate=`date +%H%M`
	date_filename=`date +%Y%m%d`
	if [ "${date_rotate}" = "0000" ]
	then
		log_all "Rotating log file"
		mv "${LOG_FILE}" "${LOG_FILE}.${date_filename}"
		bzip2 "${LOG_FILE}.${date_filename}"
		mv "${LOG_FILE}.${date_filename}" `echo "${LOG_FILE}.${date_filename}" | sed s/"logs"/"logs\/archive"/`
		touch "${LOG_FILE}"
	fi
}

MODE=$1
STOPPED=0

log_rotate

log_info "Looking for running tomcat"

PID=`find_tomcat_pid`
if [ "x${PID}" = "x" ]
then
	log_all "Tomcat is stopped, no need to stop it"
	STOPPED=1
else
	log_all "Found running tomcat with pid ${PID}"
	if [ "x$MODE" = "xrestart" ]
	then
		log_all "Tomcat is running, stopping"
		log_debug "executing sh -c \"${TOMCAT_SHUTDOWN_SCRIPT}\""
		sh -c "${TOMCAT_SHUTDOWN_SCRIPT}" #> /dev/null 2>&1
		
		log_info "Waiting for tomcat (${PID})..."
		for ((i=0;i<60;i++))
		do
			sleep 2
			if [ `check_for_pid $PID` -eq "0" ]
			then
				break
			else
				log_info "Still running, waiting..."
			fi
		done
		if [ `check_for_pid $PID` -eq "0" ]
                then
                        log_all "Stopped"
                else
                        log_all "Killing"
                        kill -9 $PID
                fi
		STOPPED=1
	else
		STOPPED=0
		log_info "Only checking, no restart at this time"
	fi
fi

if [ "$STOPPED" -eq "1" ]
then
	log_info "Removing apps..."
	rm -rf ${TOMCAT_HOME}/webapps/p4webportal ${TOMCAT_HOME}/webapps/p4webportal_beta
	log_info "Starting tomcat..."
	log_debug "executing sh -c \"${TOMCAT_STARTUP_SCRIPT}\""
	sh -c "${TOMCAT_STARTUP_SCRIPT}" #> /dev/null 2>&1
	log_info "Checking..."
	PID=`find_tomcat_pid`
	if [ ! "x${PID}" = "x" ]
	then
		log_all "Tomcat started with pid ${PID}, exiting"
		exit 0
	else
		log_error "Something wrong!!"
	fi
fi
rm -f /home/tomcat/tomcat_watchdog/tomcat_watchdog.pid
