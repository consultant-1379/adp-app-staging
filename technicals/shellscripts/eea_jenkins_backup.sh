#!/bin/bash

#===============================================================================
#
#          FILE: eea_jenkins_backup.sh
#
#         USAGE: eea_jenkins_backup.sh --host <hostname>
#
#   DESCRIPTION: This script creates jenkins backup.
#                Jenkins home folder is backed up without excluded subfolders:
#                  - workspace
#                  - fingerprints
#                  - archive, htmlreports from build subfolder
#
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Milan Gostovic (emilgos), milan.gostovic@ericsson.com
#  ORGANIZATION: Ericsson Nikola Tesla d.d.
#       CREATED: 2020-09-25
#      REVISION: ---
#===============================================================================

## su - eceaproj
## crontab -l
## 0 2 * * 1-6 /proj/cea/tools/environments/env-seliius27113/jenkins/eea_jenkins_backup.sh --host seliius27113 > /proj/cea/tools/environments/env-seliius27113/jenkins/jenkins.dump.log 2>&1


#### PATH
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin

#### Configuration
BACKUP_FILES_KEEP_NUMBER=7
#BACKUP_FILES_KEEP_DAYS=7

BANNER="EEA Jenkins Backup (version 1.0, 2020-09-25)"
DATE=$(date +%Y%m%d_%H%M)
NICE_CMD="nice"
NICE_PRIORITY="-10"

DEBUG=0 # debug not used (default)
# DEBUG=1 # debug used

#### Logging
# LOG_ENABLED=0 # disable logs
LOG_ENABLED=1 # enable logs
LOG_FILE="${0}.log"
LOG_FILE_SIZE_BYTES=10485760
# LOG_FILE_SIZE_BYTES=1048
LOG_FILE_NUMBERS=5

#### Exit values
EXIT_OK=0
EXIT_ERROR=1


###############################################################################
#### Functions
###############################################################################

function __printf()
{
    ## defining colors for outputs
    RED='\033[31m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
    BOLD='\033[1m'
    NORMAL='\033[m'

    [ "${3-}" = "nolb" ] && ECHOSWITCH="-ne" || ECHOSWITCH="-e"

    if [[ ! -z ${2-} && ! -z ${1-} ]]
    then
        case ${2} in
            error)
                echo -e "${RED}${1}${NORMAL}" >&2
                ;;
            info)
                echo ${ECHOSWITCH} "${YELLOW}${1}${NORMAL}"
                ;;
            success)
                echo -e "${GREEN}${1}${NORMAL}"
                ;;
            header)
                echo -e "${BOLD}${1}${NORMAL}"
                ;;
            debug)
                [ ${DEBUG-} -eq 1 ] && echo -e "${1}"
                ;;
            log)
                if [ ${LOG_ENABLED-} ]
                then
                    echo -e "$(date +%Y%m%d.%H%M%S);${1}" >> "${LOG_FILE-}"
                fi
                ;;
            *)
                echo -e "${1}"
                ;;
        esac
    else
        echo "${1}"
    fi
}


function __logrotate()
{
    __printf "Logrotate ..." info

    log_file_name=${1}
    log_file_size_bytes=${2}
    log_file_numbers=${3}

    __printf "log file name = '${log_file_name}'" debug
    __printf "log file size bytes = '${log_file_size_bytes}'" debug
    __printf "log file numbers = '${log_file_numbers}'" debug

    touch "${log_file_name}"

    log_size=$(wc -c "${log_file_name}" | sed 's/^ *//;s/ *$//' | awk '{ print $1 }')
    __printf "log size '${log_file_name}' = '${log_size}' bytes" debug

    if [ "${log_size}" -ge "${log_file_size_bytes}" ];
    then
        __printf "log size '${log_file_name}' > ${log_file_size_bytes} bytes" debug

        m=${log_file_numbers}

        while [ "${m}" -gt 0 ]
        do
            n=$((m-1))

            if [ -f "${log_file_name}".${n}.bz2 ]
            then
                __printf "mv ${log_file_name}.${n}.bz2 ${log_file_name}.${m}.bz2" debug
                mv "${log_file_name}".${n}.bz2 "${log_file_name}"."${m}".bz2
            fi

            m=${n}
        done

        cp -p "${log_file_name}" "${log_file_name}".1
        __printf "cp -p ${log_file_name} ${log_file_name}.1" debug > "${log_file_name}"
        bzip2 "${log_file_name}".1
    else
        __printf "log size '${log_file_name}' < ${log_file_size_bytes} bytes" debug
    fi
}


function __print_header()
{
  __printf "${BANNER}" header
}


function __done()
{
  __printf "Done!" info
  __printf "Done!" log
}

function __start()
{
  __printf "==== Backup started! ===" info
  __printf "==== Backup started! ===" log
}


function __check_dir()
{
  __printf "Check dir" info

  #### Arguments
  arg1=${1}
  __printf "arg1='${arg1}'" debug

  #### Check Directory
  if [ ! -d "${arg1}" ]
  then
      __printf "Directory '${arg1}' does not exist!" log
      __printf "Creating directory.." log
      mkdir -p "${arg1}"
  else
      __printf "Directory '${arg1}' exist!"
      __printf "Directory '${arg1}' exist!" log
  fi
}


function __jenkins_jobs_config()
{
  __printf "Jenkins Jobs Config" info
  #### Jenkins Jobs Config
  DATE=$(date +%Y%m%d_%H%M)
  dir1=$(echo "${JENKINS_HOME_DIR_JOBS}" | sed "s#/#_#g;s#^_##g")
  file1txt="${JENKINS_HOME_DIR_BACKUP}/jenkins.config_list.${dir1}.${DATE}.txt"
  file1bz2="${JENKINS_HOME_DIR_BACKUP}/jenkins.config_list.${dir1}.${DATE}.txt.bz2"
  file2tarbz2="${JENKINS_HOME_DIR_BACKUP}/jenkins.jobs.${dir1}.${DATE}.tar.bz2"
  __printf "dir1='${dir1}'" debug
  __printf "file1txt='${file1txt}'" debug
  __printf "file1bz2='${file1bz2}'" debug
  __printf "file2tarbz2='${file2tarbz2}'" debug

  __printf "Creating '${file1txt}', '${file2tarbz2}' ..."
  find "${JENKINS_HOME_DIR_JOBS}"/ -name "*config*.xml" > "${file1txt}"

  if [ -e "${file1txt}" ]
  then
    __printf "Compressing '${file2tarbz2}' ..." success
    __printf "Compressing '${file2tarbz2}' ..." log

    __printf "# ${NICE_CMD} ${NICE_PRIORITY} tar -cjf ${file2tarbz2} -T ${file1txt}" debug
    ${NICE_CMD} ${NICE_PRIORITY} tar -cjf "${file2tarbz2}" -T "${file1txt}"

    __printf "Compressing '${file1txt}' ..." success
    __printf "Compressing '${file1txt}' ..." log

      ${NICE_CMD} ${NICE_PRIORITY} bzip2 -9 "${file1txt}"
  else
      __printf "File '${file1txt}' NOT found!" error
      __printf "File '${file1txt}' NOT found!" log

  fi

  if [ -e "${file1bz2}" ]
  then
      __printf "Jenkins Jobs Config '${file1bz2}' created!" success
      __printf "Jenkins Jobs Config '${file1bz2}' created!" log
  else
      __printf "Jenkins Jobs Config '${file1bz2}' NOT created!" error
      __printf "Jenkins Jobs Config '${file1bz2}' NOT created!" log

  fi

  if [ -e "${file2tarbz2}" ]
  then
      __printf "Jenkins Jobs '${file2tarbz2}' created!" success
      __printf "Jenkins Jobs '${file2tarbz2}' created!" log
  else
      __printf "Jenkins Jobs '${file2tarbz2}' NOT created!" error
      __printf "Jenkins Jobs '${file2tarbz2}' NOT created!" log
  fi
}


function __jenkins_backup()
{
    __printf "Jenkins Backup" info

    #### Exclude file
    __printf "Creating '${TAR_EXCLUDE_FILE}' ..."

    rm -f "${TAR_EXCLUDE_FILE}"

    for dir in "${JENKINS_HOME_DIR_EXCLUDE[@]}";
    do
        __printf "dir='${dir}'" debug
        echo "${dir}" >> "${TAR_EXCLUDE_FILE}"
        exclude="${exclude} --exclude=${dir}"
    done
    __printf "exclude='${exclude}'" debug

    ## add archive and htmlreports folders to exclude. search in job folders
    find "${JENKINS_HOME_DIR_JOBS}" -name archive >> "${TAR_EXCLUDE_FILE}"
    find "${JENKINS_HOME_DIR_JOBS}" -name htmlreports >> "${TAR_EXCLUDE_FILE}"

    if [ -e "${TAR_EXCLUDE_FILE}" ]
    then
        __printf "Jenkins Tar Exclude File '${TAR_EXCLUDE_FILE}' created!" success
        __printf "Jenkins Tar Exclude File '${TAR_EXCLUDE_FILE}' created!" log

    else
        __printf "Jenkins Tar Exclude File '${TAR_EXCLUDE_FILE}' NOT created!" error
        __printf "Jenkins Tar Exclude File '${TAR_EXCLUDE_FILE}' NOT created!" log
        exit ${EXIT_ERROR};
    fi

    #### Jenkins Backup - 'home' dir
    dir1=$(echo "${JENKINS_HOME_DIR}" | sed "s#/#_#g;s#^_##g")
    file1tarbz2="${JENKINS_HOME_DIR_BACKUP}/jenkins.home.${dir1}.${DATE}.tar.bz2"
    __printf "dir1='${dir1}'" debug
    __printf "file1tarbz2='${file1tarbz2}'" debug

    __printf "Creating '${file1tarbz2}' from '${JENKINS_HOME_DIR}' ..."

    __printf "# ${NICE_CMD} ${NICE_PRIORITY} tar cjf ${file1tarbz2} -X ${TAR_EXCLUDE_FILE} ${JENKINS_HOME_DIR}" debug
    ${NICE_CMD} ${NICE_PRIORITY} tar cjf "${file1tarbz2}" -X "${TAR_EXCLUDE_FILE}" "${JENKINS_HOME_DIR}"

    if [ -e "${file1tarbz2}" ]
    then
        __printf "Jenkins Backup File '${file1tarbz2}' created!" success
        __printf "Jenkins Backup File '${file1tarbz2}' created!" log
    else
        __printf "Jenkins Backup File '${file1tarbz2}' NOT created!" success
        __printf "Jenkins Backup File '${file1tarbz2}' NOT created!" log
    fi

    #rm -f ${TAR_EXCLUDE_FILE}

}

function __jenkins_backup_remove()
{
    __printf "Jenkins Backup Remove" info

    #### Arguments
    backup_dir=${1}
    file=${2}
    backup_files_keep_number=${3}
    __printf "backup_dir='${backup_dir}'" debug
    __printf "file='${file}'" debug
    __printf "backup_files_keep_number='${backup_files_keep_number}'" debug

    #### Remove config
    backup_files=$(find "${backup_dir}"/"${file}"* -maxdepth 1 -type f | wc -l | sed 's/^ *//')
    #backup_files_list=( $(find "${backup_dir}"/"${file}"* -maxdepth 1 -type f | sort -n) )
    mapfile -t backup_files_list < <(find "${backup_dir}"/"${file}"* -maxdepth 1 -type f | sort -n)
    __printf "backup files='${backup_files}'" debug
    __printf "backup files list='${backup_files_list[*]}'" debug

    if [ "${backup_files}" -ge "${backup_files_keep_number}" ]
    then
        counter=1
        remove_limit=$((backup_files-backup_files_keep_number))
        __printf "remove_limit='${remove_limit}'" debug

        for i in "${backup_files_list[@]}"
        do
            __printf "counter='${counter}' i='${i}'"

            if [ ${counter} -le ${remove_limit} ]
            then
                rm "${i}"
                __printf "Remove '${i}'" success
                __printf "Remove '${i}'" log
            else
                __printf "Keep '${i}'" success
                __printf "Keep '${i}'" log
            fi

            counter=$((counter + 1))
        done
    else
        __printf "Skip removing '${backup_dir}/${file}*' ..." success
        __printf "Skip removing '${backup_dir}/${file}*' ..." log
    fi
}

function __usage()
{
  __printf "Usage:" log
  __printf "Usage:" info
  __printf "./eea_jenkins_backup.sh --host <hostname>" log
  __printf "./eea_jenkins_backup.sh --host <hostname>" info
  __printf "Log file: ${LOG_FILE}"

}

function __checkArguments() {
    for i in "$@"; do

        if [[ "$1" =~ ^--.* ]]; then

            CURRENT_ARG_NAME="$(echo "${1}" | tr -d -)"

            if [[ "$2" =~ ^--.* ]]; then
                __printf "Invalid argument value format for: ${2}. Argument values (following an argument flag) must not start with double dashes (--)." log
                __printf "Invalid argument value format for: ${2}. Argument values (following an argument flag) must not start with double dashes (--)." error
                exit ${EXIT_ERROR};
            elif [[ "$2" =~ ^-.* ]]; then
                __printf "Invalid argument value format for: ${2}. Argument values (following an argument flag) must not start with single dash (-)." log
                __printf "Invalid argument value format for: ${2}. Argument values (following an argument flag) must not start with single dash (-)." error
                exit ${EXIT_ERROR};
            fi

            case "${CURRENT_ARG_NAME}" in
                host)
                    if [ "${2}" != "" ] ; then
                      HOST="${2}"
                    else
                      __printf "Host parameter must not be empty!" log
                      __printf "Host parameter must not be empty!" error
                      __usage
                      exit ${EXIT_ERROR};
                    fi
                    ;;
                  *)
                      __printf "Invalid argument: ${1}." log
                      __printf "Invalid argument: ${1}." error
                      __usage
                      exit ${EXIT_ERROR};
                  ;;
                  esac
                  shift 2
        else
            if [ "$1" != "" ] ; then
                __printf "Invalid argument: ${1}." log
                __printf "Invalid argument: ${1}." error
                __usage
                exit ${EXIT_ERROR};
            fi
        fi
    done
}


###############################################################################
#### Main
###############################################################################
__start
__checkArguments "$@"

source "/proj/cea/tools/environments/env-$HOST/setup-env.sh"

## JENKINS_HOME and DEV_HOME are defined in setup-env.sh
JENKINS_HOME_DIR="$JENKINS_HOME"
JENKINS_HOME_DIR_BACKUP="${DEV_HOME}/jenkins/backup"
JENKINS_HOME_DIR_JOBS="${JENKINS_HOME_DIR}/jobs"
JENKINS_HOME_DIR_EXCLUDE=(
#   "${JENKINS_HOME_DIR}/jobs"
    "${JENKINS_HOME_DIR}/workspace"
    "${JENKINS_HOME_DIR}/fingerprints"
)

TAR_EXCLUDE_FILE="${JENKINS_HOME_DIR_BACKUP}/tar.exclude.${DATE}.txt"

__print_header
__logrotate "${LOG_FILE}" "${LOG_FILE_SIZE_BYTES}" "${LOG_FILE_NUMBERS}"

__check_dir "${JENKINS_HOME_DIR_BACKUP}"
##__jenkins_jobs_config
__jenkins_backup

__jenkins_backup_remove "${JENKINS_HOME_DIR_BACKUP}" "jenkins.config_list" ${BACKUP_FILES_KEEP_NUMBER}
__jenkins_backup_remove "${JENKINS_HOME_DIR_BACKUP}" "jenkins.jobs" ${BACKUP_FILES_KEEP_NUMBER}
__jenkins_backup_remove "${JENKINS_HOME_DIR_BACKUP}" "jenkins.home" ${BACKUP_FILES_KEEP_NUMBER}
__jenkins_backup_remove "${JENKINS_HOME_DIR_BACKUP}" "tar.exclude" ${BACKUP_FILES_KEEP_NUMBER}

__done

exit ${EXIT_OK};

###############################################################################
####  END
###############################################################################
