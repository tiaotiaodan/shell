#!/bin/bash

#Data/time
CTIME=$(date "+%F-%H-%M")

#shell ENV
SHELL_NAME="deploy.sh"
SHELL_DIR="/data/deploy"
SHELL_LOG="${SHELL_DIR}"/"${SHELL_NAME}.log"
LOCK_FILE="/tmp/${SHELL_NAME}.lock"

#APP ENV
PNAME="demo"
CODE_DIR="/data/deploy/code"			
CONFIG_DIR="/data/deploy/config/" 		#存放配置文件目录
TMP_DIR="/data/deploy/tmp"       		#建立临时目录
TAR_DIR="data/deploy/tar"       		#存放包的位置
PKG_SERVER="192.168.3.177"     			#存放包的服务器


shell_log(){
	LOG_INFO=$1
	echo "$CTIME  ${SHELL_NAME}  :  ${LOG_INFO}"  >> ${SHELL_LOG}
}

shell_lock(){
	touch "${LOCK_FILE}"
}

shell_unlock(){
	rm -f "${LOCK_FILE}"
}

usage(){
	echo "Usage:  $0 [env deploy version] | rollback-list  | rollback  |fastrollback "
}


get_pkg(){
	echo "get pkg"
}

config_pkg(){
	echo "config pkg"
}

scp_pkg(){
	echo "scp pkg"
}

deploy_pkg(){
	echo "deploy pkg"
}

test_pkg(){
	echo "test pkg"
}

fast_rollback(){
	echo "fast rollback"
}

rollback(){
	echo "rollback"
}

rollback_list(){
	echo "rollback list"
}

main(){
	DEPLOY_ENV=$1
	DEPLOY_TYPE=$2
	DEPLOY_VER=$3
	if [ -f "${LOCK_FILE}" ]
		then
		shell_log "${SHELL_NAME}" is running
		echo "${SHELL_NAME}" IS running && exit
	fi
	shell_lock;
	case $DEPLOY_TYPE in
		deploy)
			get_pkg
			config_pkg
			scp_pkg
			deploy_pkg
			test_pkg
			;;
		rollback)
			rollback $DEPLOY_VER
			;;
		fast_rollback)
			fast_rollback
			;;
		rollback-list)
			rollback-list
			;;
		*)
			usage
	esac
	shell_unlock;
}

main $1 $2 $3