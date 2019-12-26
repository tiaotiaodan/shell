#!/bin/sh
#author:shichao
#date:2018/08/02
#mail:shichao@scajy.cn

[ -f /etc/init.d/functions ] && . /etc/init.d/functions  ||exit

function Basics(){

 #安装epel，源
echo "epel源安装中，请稍等......"
rpm -ivh http://mirrors.ustc.edu.cn/epel/7/x86_64/Packages/e/epel-release-7-12.noarch.rpm > /dev/null 2>&1 
echo "epel源安装完成!"

echo "gcc-c++,gcc,make等工具安装中，请稍等......"
yum -y install gcc gcc-c++ gd cmake patch autoconf libjpeg libjpeg-devel libpng libpng-devel freetype libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel  ncurses ncurses-devel curl curl-devel e2fsprogs  krb5-devel libidn  libidn-devel openssl  openldap-devel nss_ldap openldap-clients openldap-servers pcre-devel libmcrypt-devel   > /dev/null 2>&1 
if [ $? -eq 0 ] ; then
    echo "gcc-c++,gcc,make等工具安装完成!"
fi

#系统基本设置，包括时间同步设置，firewalld，root禁止登陆等
#系统时间及时区设置


/usr/bin/timedatectl set-timezone  Asia/Shanghai  
echo "正在同步网络时间......"
/usr/sbin/ntpdate cn.pool.ntp.org > /dev/null 2>&1 && echo "网络时间同步完成！" || echo "网络时间同步失败"
/sbin/hwclock --systohc  


#设置为每天同步网络时间
is_ntpdate=$(grep "ntpdate" /var/spool/cron/root |wc -l)
if [ $is_ntpdate -eq 0 ] ; then
cat >> /var/spool/cron/root <<EOF 
59  23 * * * /usr/sbin/ntpdate cn.pool.ntp.org > /dev/null
EOF
fi

#禁用selinux和firewalld
/usr/bin/sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config > /dev/null 2>&1  && echo "已禁用系统selinux"
/usr/bin/systemctl  stop firewalld  > /dev/null 2>&1
/usr/bin/systemctl disable firewalld >  /dev/null 2>&1


#系统升级
echo "系统正在升级中......该过程可能需要十几分钟或更久，请稍等！"
yum update -y > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo "系统升级成功"
fi





#系统参数优化
echo "正在优化系统参数......"
sed -i '5,$d' /etc/security/limits.d/20-nproc.conf
cat >> /etc/security/limits.d/20-nproc.conf <<EOF 
*          soft    nproc     655350
*          soft    nofile    655350
*          hard    nofile    655350
*          hard    nproc     655350
root       soft    nproc     unlimited
EOF
echo 10240 >  /proc/sys/net/core/somaxconn

echo never > /sys/kernel/mm/transparent_hugepage/enabled  &&  echo never > /sys/kernel/mm/transparent_hugepage/defrag

sysctl vm.overcommit_memory=1 > /dev/null 2>&1 

sed -i '10,$d' /etc/sysctl.conf
cat >> /etc/sysctl.conf <<EOF 
vm.overcommit_memory = 1
net.ipv4.tcp_syncookies = 0
net.ipv4.ip_local_port_range = 1024 65535
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_window_scaling = 0
net.ipv4.tcp_sack = 0
net.core.netdev_max_backlog = 30000
net.ipv4.tcp_no_metrics_save=1
net.core.somaxconn = 65535
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_keepalive_time = 40
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 10
EOF
echo "系统参数已经优化!"


#配置开机启动项
echo '' > /etc/init.d/optimizing
cat >> /etc/init.d/optimizing <<EOF 
#!/bin/bash
### BEGIN INIT INFO
# Provides:          optimizing
# Required-Start:    \$local_fs
# Required-Stop:
# X-Start-Before:    redis mongod mongodb-mms-automation-agent
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Optimizing script
# Description:       Optimizing script.
### END INIT INFO

case \$1 in
  start)
    # transparent hugepage
    thp_path=/sys/kernel/mm/transparent_hugepage
    echo 'never' > \${thp_path}/enabled
    echo 'never' > \${thp_path}/defrag

    # somaxconn
    echo '10240' > /proc/sys/net/core/somaxconn  
    ulimit -f unlimited
    ulimit -t unlimited
    ulimit -v unlimited
    ulimit -n 655350
    ulimit -m unlimited
    ulimit -c unlimited
    ulimit -u 655350
    unset thp_path
    ;;
esac
EOF
if [ $? -eq 0 ] ;then 
   chmod 755 /etc/init.d/optimizing 
   chkconfig optimizing on 
fi

}

#创建staff用户
function  USER(){
/usr/bin/id staff > /dev/null 2>&1
if [ $? -ne 0 ] ; then
    while 1>0 ;do
        passwd=`cat   /dev/urandom | strings -n 12 | head -n 1 | sed 's/ /?/g'`
        if [ $passwd = $passwd ] ; then
            /usr/sbin/useradd staff > /dev/null 2>&1
            echo staff:$passwd | chpasswd
            echo "已经创建staff用户,请牢记staff密码:  $passwd"
            break
        else
            echo "两次输入密码不一致,请重新输入!"
        fi
    done
else
   echo "staff用户已经存在!"
fi
}

function ROOT(){
#禁止root登录
    is_permitrootlogin=$(/usr/bin/sed -ne '/^PermitRootLogin.*$/p' /etc/ssh/sshd_config |wc -l)
    is_allowusers=$(/usr/bin/sed -ne '/^AllowUsers.*$/p' /etc/ssh/sshd_config | wc -l)
    if [ $is_permitrootlogin -eq 0 ] ; then 
        sed -i '/#MaxSessions 10/a\PermitRootLogin no' /etc/ssh/sshd_config
    else 
        sed -i 's/^PermitRootLogin.*$/PermitRootLogin no/' /etc/ssh/sshd_config
    fi
    if [ $is_allowusers -eq 0 ] ; then 
        sed -i '/PermitRootLogin no/a\AllowUsers *@218.6.242.42' /etc/ssh/sshd_config
    else 
        sed -i 's/^AllowUsers.*$/AllowUsers *@218.6.242.42/' /etc/ssh/sshd_config
    fi
    systemctl restart sshd.service
    echo "已禁用root登陆,且其他用户只能从218.6.242.42登录"
}


function NGINX(){
    rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm >/dev/null 2>&1
    return=$?
    if [ "${return}"  -eq 0 ]
        then
            action "nginx源安装完成"  /bin/true
            
    else
         action "nginx源已经安装"  /bin/false
    fi
    
    is_nginx=$(rpm -qa  nginx | wc -l)
    if [ $is_nginx -ne 0 ] ;then 
        NGINX_version=$(rpm -qa nginx | awk -F "-" '{print $1,"-",$2}')
        echo "nginx已经安装,版本为："$NGINX_version  
    else
        echo "nginx安装中,请稍等......"
        yum install -y  nginx > /dev/null 2>&1
        return=$?
        if [ $? -eq 0 ] ; then
            action "nginx安装完成"  /bin/true
        fi
    fi
    
    echo "nginx正在启动，请稍等........"
    /bin/systemctl start nginx.service
    return=$?
    if [ "${return}"  -eq 0 ]
        then
            action "nginx启动"  /bin/true
            
    else
         action "nginx启动"  /bin/false
    fi
    systemctl enable nginx.service
}


function REDIS(){
    is_redis=$(rpm -qa  redis | wc -l)
    if [ $is_redis -ne 0 ] ; then 
        redis_version=$(redis-server -v | awk '{print $3}' | cut -d "=" -f 2)
        echo "redis已经安装,版本为：redis-server-"$redis_version
    else
        echo "redis安装中,请稍等......"
        yum install -y http://118.24.186.59:8080/redis-3.2.12-2.el7.x86_64.rpm > /dev/null 2>&1  ;
        if [ $? -eq 0 ] ; then
            echo "redis安装完成!"
        fi
    fi
    /bin/systemctl start redis
    /bin/systemctl enable redis
}


function MARIADB(){
    is_mariadb=$(rpm -qa  mariadb | wc -l)
    if [ $is_mariadb -ne 0 ] ; then
        mariadb_version=$(mysql --version | awk '{print $5}' |cut -d '-' -f 1)
        echo "mariadb已经安装,版本为：mariadb-"$mariadb_version
    else
        echo "mariadb安装中,请稍等......"
        wget http://118.24.186.59:8080/mariadb-5.5.zip ;
        unzip ./mariadb-5.5.zip ;
        yum install -y  ./mariadb*.rpm > /dev/null ;
        if [ $? -eq 0 ] ; then
            echo "mariadb安装完成!"
        fi
        rm ./mariadb-* -rf;
    fi

}

function Mongo(){
    echo "Mongo-3.4下载安装中,请稍等......"
    mkdir /root/mong3.4 -p
    cd /root/mong3.4/
    collections_name=(
        mongodb-org-mongos
        mongodb-org-server
        mongodb-org-shell
        mongodb-org-tools
        mongodb-org
    )
    for(( i=0;i<${#collections_name[@]};i++)) 
    do
        is_n=$(rpm -qa ${collections_name[i]} | wc -l)
            if [ $is_n -eq 0 ] ; then
                wget http://118.24.186.59:8080/3.4/${collections_name[i]}-3.4.1-1.el7.x86_64.rpm > /dev/null 2>&1
                yum install -y ${collections_name[i]}-3.4*  > /dev/null 
            fi
    done
    echo "Mongo-3.4安装完成！"

}

function PHP(){
    rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm > /dev/null 2>&1 
    return=$?
    if [ "${return}"  -eq 0 ]
        then
            action "PHP源安装"  /bin/true
            
    else
         action "PHP源安装"  /bin/false
    fi
    
    is_nginx=$(rpm -qa  php | wc -l)
    if [ $is_nginx -ne 0 ] ;then 
        MYSQL_version=$(rpm -qa php | awk -F "-" '{print $1,"-",$2}')
        echo "php已经安装,版本为："$MYSQL_version  
    else
        echo "php安装中,请稍等......"
       yum --enablerepo=remi-php72 install -y  php php-fpm php-opcache php-redis php-mbstring php-mcrypt php-geoip php-gd php-mongodb php-openssl php-xml php-process php-pdo php-posix php-zip php-pear php-sockets php-mysql php-mysqli php-sockets  php-devel php-bcmath  php-pgsql  > /dev/null 2>&1
        return=$?
        if [ $? -eq 0 ] ; then
            action "php安装完成"  /bin/true
        fi
    fi
    echo "php正在启动，请稍等........"
    /bin/systemctl start php-fpm   #启动服务
    return=$?
    if [ "${return}"  -eq 0 ]
        then
            action "php启动"  /bin/true
           
    else
         action "php启动"  /bin/false
    fi
    systemctl enable php-fpm              #添加服务自启动
}

function LNP() {
#php配置
echo "php及nginx相关参数配置中......"
/usr/bin/sed -i 's/^short_open_tag.*$/short_open_tag = On/' /etc/php.ini
/usr/bin/sed -i 's/^upload_max_filesize.*$/upload_max_filesize = 100M/' /etc/php.ini
/usr/bin/sed -i 's/^post_max_size.*$/post_max_size = 100M/' /etc/php.ini
/usr/bin/sed -i 's/^error_reporting.*$/error_reporting = E_ALL/' /etc/php.ini
/usr/bin/sed -i 's/^display_errors.*$/display_errors = On/' /etc/php.ini
/usr/bin/sed -i 's/^log_errors =.*$/log_errors = On/' /etc/php.ini
is_timezone=$(/usr/bin/sed -n '/^date.timezone.*$/p'  /etc/php.ini  | wc -l)
if [ $is_timezone -eq 0 ] ; then 
    /usr/bin/sed -i '/;date.timezone/a\date.timezone = Asia\/Shanghai' /etc/php.ini
else 
    /usr/bin/sed -i 's/^date.timezone.*$/date.timezone = Asia\/Shanghai/' /etc/php.ini
fi

#php-fpm配置
/usr/bin/sed -i 's/^pm.max_children =.*$/pm.max_children = 1024/' /etc/php-fpm.d/www.conf
/usr/bin/sed -i 's/^pm.start_servers.*$/pm.start_servers = 50/' /etc/php-fpm.d/www.conf
/usr/bin/sed -i 's/^pm.min_spare_servers.*$/pm.min_spare_servers = 50/' /etc/php-fpm.d/www.conf
/usr/bin/sed -i 's/^pm.max_spare_servers.*$/pm.max_spare_servers = 150/' /etc/php-fpm.d/www.conf
/usr/bin/sed -i 's/^user = apache/user = staff/' /etc/php-fpm.d/www.conf
/usr/bin/sed -i 's/^group = apache/group = staff/' /etc/php-fpm.d/www.conf
/usr/bin/sed -i 's/^;rlimit_files = 1024/rlimit_files = 65535/'  /etc/php-fpm.d/www.conf

#nginx配置
rm -rf /etc/nginx/conf.d/default.conf
echo '' > /etc/nginx/nginx.conf
cat >> /etc/nginx/nginx.conf <<EOF 
user  staff staff;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
worker_rlimit_nofile 65535;

events {
    use   epoll;
    worker_connections  65535;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    
    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
EOF

echo "php及nginx相关参数配置完成！"

/bin/systemctl restart php-fpm
/bin/systemctl restart nginx
}


while : 
do
    
    cat <<EOF
        +---------------------------------------------------------------+
        |                                                               |
        |         This  is  a LNMP                                      |
        |                                                               |
        |         1.必须先执行 '1' 安装linux环境基础                    |
        |         2.安装Nginx                                           |
        |         3.安装PHP                                             |
        |         4.安装redis                                           |
        |         5.安装Mongo                                           |
        |         6.安装linux的nginx和php                               |
        |         7.配置Nginx和PHP环境                                  |
        |         8.安装redis和mongo数据库                              |
        |         9.退出安装程序                                        |
        +---------------------------------------------------------------+
EOF
    read -p "请你输入一个数字:" num
    case "$num" in
        1)
            Basics
            USER
            ROOT
        ;;
        2)
            NGINX
            ;;
        3)
            PHP
        ;;
        4)
            REDIS
        ;;
        5)
            Mongo
        ;;
        6)
            NGINX
            PHP
        ;;
        7)
            LNP
        ;;
        8)
           REDIS
           Mongo
        ;;       
        9)
           exit 
        ;;
        *)
        echo '输入错误，已重新加载....'
        ;;
    esac
	
done

