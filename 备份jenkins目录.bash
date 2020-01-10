#!/bin/bash
#cut the jenkins 

LOGS_PATH=/home/staff/.jenkins
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
JENKINS_PATH=/backup/jenkins

[ -d ${JENKINS_PATH} ] && echo  ${JENKINS_PATH} In existence || mkdir -p  ${JENKINS_PATH}

cp -a ${LOGS_PATH}  ${JENKINS_PATH}/jenkins_${YESTERDAY}

cd ${JENKINS_PATH}
tar -czPf jenkins_${YESTERDAY}.tar.gz jenkins_${YESTERDAY}




find ${JENKINS_PATH}  -type d -mtime +10 |xargs rm -rf





mkdir -p /scripts/
vim /scripts/jenkins.sh 

00 0 * * * /bin/bash /scripts/nginx_log.sh  > /dev/null 2>&1   #nginx 每天完成凌晨0点0分日志切割