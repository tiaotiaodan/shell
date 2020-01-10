#!/bin/sh
#author:shichao
#date:2018/08/02
#mail:shichao@scajy.cn

# Source function library.
. /etc/rc.d/init.d/functions

nginx_dir='/opt/nginx/sbin/nginx'
nginx_pid_file='/opt/nginx/logs/nginx.pid'
nginx_conf_file='/opt/nginx/conf/nginx.conf'
if [ $# -ne 1  ]
	then
		echo "Usage $0 nginx {start|stop|restart}"
		exit
fi
function start() {
	"${nginx_dir}" -c "${nginx_conf_file}"
		[ $? -eq 0 ] && action "正在启动 nginx:" /bin/true || \
		action "正在启动 nginx:" /bin/false
}

function stop() {
	kill -TERM `cat $nginx_pid_file`
               [ $? -eq 0 ] && action "停止 nginx:" /bin/true || \
	action "停止 nginx:" /bin/false
}

function restart(){
	stop
	start
}

function configtest(){
	"${nginx_dir}" -t -c "${nginx_conf_file}"
}

function reload(){
        configtest || return 6
	ps auxww | grep nginx | grep master | awk '{print $2}' |xargs kill -HUP
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
	configtest)
		configtest
	;;
	reload)
		reload
	;;
	*)
		echo "Usage:$0  {start|stop|restart}"
		exit
	;;
esac