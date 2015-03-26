#! /bin/bash -
#
# No-PPT 自动线上部署脚本。
#
# Grammar:
#       jetty_deploy.sh   -g {groupId} -a {artifactId} [-v {version}]
#
# @author   ISME
# @version  1.0.1
# @since    1.0.0
#

# Reset IFS
IFS=$'\040\t\n'

# Reset PATH
OLDPATH="${PATH}"
PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin"
export PATH

# Reset JAVA_HOME
JAVA_HOME="/usr/local/java"
CLASSPATH="${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar"
PATH="${JAVA_HOME}/bin:${PATH}"

export JAVA_HOME
export CLASSPATH
export PATH

################################ Global functions ################################
function info()
{
    echo -e "\e[32m[INFO]: $1\e[0m"
}

function warn()
{
    echo -e "\e[33m[WARN]: $1\e[0m"
}

function error()
{
    echo -e "\e[31m[ERROR]: $1\e[0m"
}
##################################################################################

EXITCODE=0
PROGRAM=`basename $0`
VERSION="1.0.0"

# Nexus configurations.
NEXUS_SERVER="http://dev.noppt.cn:8081/nexus/content/repositories/releases"
MAVEN_METADATA_FILE="maven-metadata.xml"

WORKING_DIR="./"                                # TODO: Modify this before used in production environment.
DOWNLOAD_TMP_DIR="./.lifter_download_tmp_"      # TODO: Modify this before used in production environment.


# Define parameters.
groupId=""
artifactId=""
version=""

function usage()
{
    echo "Usage: ${PROGRAM} [OPTIONS]..."
    echo "  -a      Project artifactId."
    echo "  -g      Project groupId."
    echo "  -v      Project version."
    echo "  -h      This help."
}

function download_file()
{
    local url="$1"
    local filename="$2"

    # Download file.
    wget -t 3 -T 60 --quiet "${url}" -O "${filename}"
    wget -t 3 -T 60 --quiet "${url}.md5" -O "${filename}.md5"

    # Checksum
    check_md5 "${filename}"
}

function check_md5()
{
    local file="$1"
    which md5sum > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            if [ "$(md5sum "${file}" | awk '{print $1}')" != "$(cat "${file}.md5")" ]
            then
                error "${file} MD5 checksum failed."
                exit 1
            fi
        else

            # For Mac OSX.
            which md5 > /dev/null 2>&1
            if [ $? -eq 0 ]
            then
                if [ "$(md5 -q "${file}")" != "$(cat "${file}.md5")" ]
                then
                    error "${file} MD5 checksum failed."
                    exit 1
                fi
            else
                error "Your system not support md5sum."
                exit 1
            fi
        fi
}

function prepare_options()
{
    # Check groupId and artifactId.
    if [ "${groupId}" = "" ] || [ "${artifactId}" = "" ]
    then
        error "Please specify groupId and artifactId."
        exit 1
    fi

    # Check version.
    if [ "${version}" = "" ]
    then

        # Maven metadata download url.
        local url="${NEXUS_SERVER}/$(echo ${groupId} | sed 's/\./\//g')/${artifactId}/${MAVEN_METADATA_FILE}"

        # Download metadata and md5 file.
        mkdir -p "${DOWNLOAD_TMP_DIR}/${groupId}/${artifactId}"
        cd "${DOWNLOAD_TMP_DIR}/${groupId}/${artifactId}/"
        download_file "${url}" "${MAVEN_METADATA_FILE}"

        # Read latest version.
        version="$(cat "${MAVEN_METADATA_FILE}" | grep "<release>.*</release>" | sed -E 's/( )*<(\/)*release>//g')"
        if [ "${version}" = "" ]
        then
            error "Get version failed. Please input version and retry."
            exit 1
        fi

        # Back to the main directory.
        cd - > /dev/null 2>&1
    fi

    # Enter project workspace.
    cd ${artifactId}
}

function download_packages()
{
    # WAR file URL.
    local filename="${artifactId}-${version}.war"
    local url="${NEXUS_SERVER}/$(echo ${groupId} | sed 's/\./\//g')/${artifactId}/${version}/${filename}"

    # Download WAR file and MD5 file.
    mkdir -p "${DOWNLOAD_TMP_DIR}/${groupId}/${artifactId}/${version}"
    cd "${DOWNLOAD_TMP_DIR}/${groupId}/${artifactId}/${version}"
    download_file "${url}" "${filename}"
    cd - > /dev/null 2>&1
}

function backup_old_version()
{
    local backup_dir=".lifter_${groupId}_${artifactId}_${version}_rollback_"
    mkdir "${backup_dir}"
    cp -r "static" "${backup_dir}"
    cp -r "webapps" "${backup_dir}"
}

function deploy_new_version()
{
    rm -rf "webapps" "static"
    mkdir "webapps"
    unzip "${DOWNLOAD_TMP_DIR}/${groupId}/${artifactId}/${version}/${artifactId}-${version}.war" -d "webapps"
    mv "webapps/static" .
}

function main()
{
    while getopts a:g:v:ch opt;
    do
        case ${opt} in
            a)
                artifactId=${OPTARG}
                ;;
            g)
                groupId=${OPTARG}
                ;;
            v)
                version=${OPTARG}
                ;;
            h)
                usage
                exit 0
                ;;
            c)
                rm -rf .lifter*
                exit 0
                ;;
            *)
                ;;
        esac
    done

    # Prepare options.
    prepare_options

    # Download packages.
    download_packages

    # Backup old version.
    backup_old_version

    # Stop service.
    bin/jetty.sh stop

    # Deploy new version.
    deploy_new_version

    # Restart service.
    bin/jetty.sh start
}

main $@
