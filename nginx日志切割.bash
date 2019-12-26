#!/bin/bash
#cut the nginx log

LOGS_PATH=/var/log/nginx
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
DIR_NAME_PATH=`ls  -l  ${LOGS_PATH}/*.log |awk -F'/' '{print $NF}' |awk -F '.' '{print $1}'`

for i in ${DIR_NAME_PATH}
do
mv ${LOGS_PATH}/${i}.log ${LOGS_PATH}/${i}_${YESTERDAY}.log

tar -czPf ${LOGS_PATH}/${i}_${YESTERDAY}.tar.gz ${LOGS_PATH}/${i}_${YESTERDAY}.log

[ -e ${LOGS_PATH}/${i}_${YESTERDAY}.log ] &&  rm -fr ${LOGS_PATH}/${i}_${YESTERDAY}.log

done

kill -USR1 $(cat /var/run/nginx.pid)
find $LOGS_PATH/  -type f -mtime +10 |xargs rm -f





mkdir -p /scripts/
vim /scripts/nginx_log.sh 

00 0 * * * /bin/bash /scripts/nginx_log.sh  > /dev/null 2>&1   #nginx 每天完成凌晨0点0分日志切割