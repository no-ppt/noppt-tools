#! /usr/bin/env bash -
#
# Nginx daemon.
#
# Comments to support chkconfig on RedHat Linux.
# ================================================================
# chkconfig:    2345 80 20
# description:  High performance HTTP reverse proxy.
# ================================================================
#
# Grammar:
#       nginxd [start] [stop] [restart]
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

################################ Global functions ################################
info()
{
    echo -e "\e[32m[INFO]: $1\e[0m"
}

warn()
{
    echo -e "\e[33m[WARN]: $1\e[0m"
}

error()
{
    echo -e "\e[31m[ERROR]: $1\e[0m"
}
##################################################################################

EXITCODE=0
PROGRAM=`basename $0`
VERSION="1.0.0"

usage()
{
    echo "Usage: ${PROGRAM} [start] [stop] [restart]"
    exit $((EXITCODE + 1))
}

if [ $# -eq 0 ]
then
    usage
fi

while test $# -gt 0
do
    case $1 in
        start)

            # Start nginx.
            ${NGINX}

            if [ $? -eq 0 ]
            then
                info "Nginx has been started."
            else
                error "Nginx start failed!"
            fi
            ;;

        stop)

            # Stop nginx.
            ${NGINX} -s stop

            if [ $? -eq 0 ]
            then
                info "Nginx has been stopped."
            else
                error "Nginx stop failed!"
            fi
            ;;

        restart)
            pid=`cat ${NGINX_HOME}/logs/nginx.pid 2>/dev/null`
            if [ -z ${pid} ]
            then
                warn "Nginx not running. Try to start it..."
                ${NGINX}
            else
                kill -HUP ${pid}

                # Check result.
                if [ $? -eq 0 ]
                then
                    info "Nginx has been restarted."
                else
                    error "Nginx restart failed!"
                fi
            fi
            ;;
        *)
            usage
            ;;
    esac
    shift
done
