#!/bin/sh
#author:shichao
#date:2018/08/02
#mail:shichao@scajy.cn

[ -f /etc/init.d/functions ] && . /etc/init.d/functions  ||exit



function NGINX(){
    rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm >/dev/null 2>&1
    return=$?
    if [ "${return}"  -eq 0 ]
        then
            action "nginx源安装"  /bin/true
            
    else
         action "nginx源安装"  /bin/false
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

function MYSQL(){
    rpm -ivh http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm >/dev/null 2>&1
    return=$?
    if [ "${return}"  -eq 0 ]
        then
            action "MYSQL源安装"  /bin/true
            
    else
         action "MYSQL源安装"  /bin/false
    fi
    
    is_nginx=$(rpm -qa  mysql | wc -l)
    if [ $is_nginx -ne 0 ] ;then 
        MYSQL_version=$(rpm -qa mysql | awk -F "-" '{print $1,"-",$2}')
        echo "mysql已经安装,版本为："$MYSQL_version  
    else
        echo "mysql安装中,请稍等......"
        yum -y install mysql-community-server mysql-community-devel > /dev/null 2>&1
        return=$?
        if [ $? -eq 0 ] ; then
            action "mysql安装完成"  /bin/true
        fi
    fi
    echo "mysql正在启动，请稍等........"
    /bin/systemctl start mysqld.service
   
    return=$?
    if [ "${return}"  -eq 0 ]
        then
            action "mysql启动"  /bin/true
            
    else
         action "mysql启动"  /bin/false
    fi
     systemctl enable mysqld.service
}

function PHP(){
    rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm >/dev/null 2>&1 
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
        yum --enablerepo=remi-php70 install -y  php php-fpm php-opcache php-redis php-mbstring php-mcrypt php-geoip php-gd php-mongodb php-openssl php-xml php-process php-pdo php-posix php-zip php-pear php-sockets php-mysql php-mysqli php-sockets > /dev/null 2>&1
        return=$?
        if [ $? -eq 0 ] ; then
            action "php安装完成"  /bin/true
        fi
    fi
    echo "php正在启动，请稍等........"
    /bin/systemctl start php-fpm
    return=$?
    if [ "${return}"  -eq 0 ]
        then
            action "php启动"  /bin/true
            
    else
         action "php启动"  /bin/false
    fi
    systemctl enable php-fpm
}

function LNMP() {
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
is_timezone=$(/usr/bin/sed -n '/^;rlimit_files.*$/p'  /etc/php-fpm.d/www.conf  | wc -l)
if [ $is_timezone -eq 0 ] ; then 
    /usr/bin/sed -i '/;rlimit_files/a\rlimit_files = 655350' /etc/php-fpm.d/www.conf
else 
    /usr/bin/sed -i 's/^rlimit_files.*$/rlimit_files = 655350/' /etc/php-fpm.d/www.conf
fi

#nginx配置
rm -rf /etc/nginx/conf.d/default.conf
echo '' > /etc/nginx/nginx.conf
cat >> /etc/nginx/nginx.conf <<EOF 
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


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

    #access_log  /var/log/nginx/access.log  main;
    access_log off;

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
        +----------------------------------+
        |                                  |
        |         This  is  a LNMP         |
        |                                  |
        |         1.安装Nginx              |
        |         2.安装MySQL              |
        |         3.安装PHP				   |
        |		  4.全量安装LNMP		   |
        |         5.配置LNMP环境           |
        |         6.退出本次安装           |
        +----------------------------------+
EOF
    read -p "请你输入一个数字:" num
    case "$num" in
        1)
            NGINX
            ;;
        2)
            MYSQL
        ;;
        3)
            PHP
        ;;
        4)
            NGINX
            MYSQL
            PHP
        ;;
        5)
            LNMP
        ;;
        6)
        exit
        ;;
        *)
        echo '输入错误，已重新加载....'
        ;;
    esac
	
done
