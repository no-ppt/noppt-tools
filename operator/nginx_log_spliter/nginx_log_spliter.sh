#! /bin/bash -
#
# Nginx log spliter.
#
# @author   luochuan
# @version  1.0.0
#

IFS=$'\040\t\n'

OLDPATH="${PATH}"
PATH="/bin:/usr/bin"
export PATH

NGINX_HOME="/usr/local/nginx"
NGINX="${NGINX_HOME}/sbin/nginx"
PID=`cat ${NGINX_HOME}/logs/nginx.pid`

EXITCODE=0
PROGRAM=`basename $0`
VERSION="1.0.0"

NOPPT_REQUEST_LOG="${NGINX_HOME}/logs/noppt/request.log"

YESTERDAY=`date +%Y%m%d --date="-1 day"`
# YESTERDAY=`date -v-1d +%Y%m%d`        # Use in FreeBSD(OS X)

mv "${NOPPT_REQUEST_LOG}" "${NOPPT_REQUEST_LOG}.${YESTERDAY}"
kill -USR1 ${PID}
sleep 1
