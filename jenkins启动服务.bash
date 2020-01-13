#!/bin/sh
#author:shichao
#date:2019/12/28
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
#mail:shichao@scajy.cn

# Source function library.

Jenkins_War_Dir=/home/staff/jenkins.war
Jenkins_Variable='-Dorg.eclipse.jetty.server.Request.maxFormContentSize=5000000 -jar  -Xms8096m -Xmx12288m   -XX:PermSize=256M -XX:MaxPermSize=512M'
Jenkins_Port='8080'
Jenkins_Pid=`ps -ef |grep jenkins.war |grep -v grep |awk '{print $2}'`

if [ $# -ne 1  ]
	then
		echo "Usage $0 jenkins {start|stop|restart}"
		exit
fi

function start() {
    su - staff -c "nohup java  ${Jenkins_Variable}  ${Jenkins_War_Dir}   --httpPort=${Jenkins_Port}   >/dev/null 2>&1 &"     #这段是指定用户启动服务
!
	[ $? -eq 1 ] && echo  "正在启动 jenkins:  [Determine]"  || \
	echo "正在启动 jenkins:  [fail]" 
}

function stop() {
	kill -9  ${Jenkins_Pid}
        [ $? -eq 0 ] && echo  "正在启动 jenkins:  [Determine]"  || \
        echo "正在启动 jenkins:  [fail]" 

}

function restart(){
	stop
	sleep 3
	start
}

case "$1" in
	start)
		start
	;;
	stop)
		stop
	;;
	restart)
		restart
	;;
	*)
		echo "Usage:$0  {start|stop|restart}"
		exit
	;;
esac
