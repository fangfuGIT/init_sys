#! /bin/bash

#Author: FF
#Date:2019-06-20
#Description: 初始化安装



function getLocalIP()
        {
              # ifconfig | grep -o 'inet [0-9.]*' | grep -o '[0-9.]*$' | grep -e '^192\.' -e '^10\.' -e '^172\.'
               ip addr | grep -o 'inet [0-9.]*' | grep -o '[0-9.]*$' | grep -e '^192\.' -e '^10\.' -e '^172\.' | head -n 1
        }



prompt()
{
        while true
        do
          echo -e -n "$1 [yes/no/exit]? "
          if [ "$CONFIRM_YES" == "1" ]; then
            echo "yes"
            echo ""
            return 0
          fi
          read PROMPT_ANSWER
          if [ -z "$PROMPT_ANSWER" ]; then
            continue
          else
            if [ "$PROMPT_ANSWER" == "yes" ]; then
              echo ""
              return 0
            elif [ "$PROMPT_ANSWER" == "no" ]; then
              echo ""
              return 1
            elif [ "$PROMPT_ANSWER" == "exit" ]; then
              echo ""
              exit 0
            else
              continue
            fi
          fi
        done
}




function init()
		{
        		localIP=`getLocalIP`
            self_name=`basename $0`
        		theFiledir=`echo $(cd "$(dirname "$0")"; pwd)`
       			cd ${theFiledir}
			     	logFile='./init.log'
		}

function check_pid()
  {
    local pid_name="$1"
    num=`ps -ef|grep ${pid_name}|wc -l`
    if [ ${num} -gt 1 ];then
      return 1
    else
      return 0
    fi
  }


function check_run()
  {   
    local run_name="$1"
    local showContent=" Failed to started, please check it. exit"
    sleep 1
    check_pid ${run_name}
    if [ $? -lt 1 ];then
      echo -e "\033[31;49;1m[`date +%F' '%T`] Error: ${run_name}${showContent}\033[39;49;0m" 
      # echo "${run_name} Failed to start successful, please check for right installation。exit"
      exit 0
    fi
  }


function check_nginx_run()
    {
        NGINXPID=$(ps -ef | grep '/usr/local/nginx/sbin/nginx' | grep -v grep | awk '{print $2}')
        if [ "$NGINXPID" != "" ]; then
            echo "nginx (pid $NGINXPID) already install."
            exit 1
        fi
    }

function mysqlInstall()
		{   
        # if [ -f ${theFiledir}/mysqlInstall_log.txt ];then
        #     rm -rf ${theFiledir}/mysqlInstall_log.txt
        # fi
				echo -e "starting Mysql install .........."| tee -a ${logFile}

	      mkdir -p /data/mysql/build
        cd /data/mysql/build
        cp -rf ${theFiledir}/mysql/*.tar.gz /data/mysql/build
        yum -y install gcc gcc-c++ ncurses ncurses-devel cmake bison
        if [ $? -eq 0 ];then
            groupadd mysql
            useradd -s /sbin/nologin -M -g mysql mysql
            tar xvf boost_1_59_0.tar.gz 
            tar xvf mysql-5.7.23.tar.gz 
        else 
            echo -e "\033[31;49;1m[`date +%F' '%T`] Error: yum install is not install\033[39;49;0m"
            exit 0
        fi

        cd mysql-5.7.23
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DMYSQL_DATADIR=/data/mysql \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_BOOST=../boost_1_59_0 \
        -DSYSCONFDIR=/etc \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DENABLED_LOCAL_INFILE=1 -DENABLE_DTRACE=0 \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_unicode_ci \
        -DWITH_EMBEDDED_SERVER=1 
            make -j `grep 'processor' /proc/cpuinfo | wc -l`
             if [ $? -ne 0 ]; then
                  make
             fi
             make install
             
          		cp -rf ${theFiledir}/mysql/my.cnf /etc/my.cnf
          		cd /data 
                rm -rf /data/mysql/build 
              	/usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql
			         	cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
                chmod 755 /etc/init.d/mysql
              	chmod +x /etc/init.d/mysql
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
                ldconfig
                ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
                ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
                systemctl enable mysqld 
                /etc/init.d/mysql start
                
                ln -sf /usr/local/mysql/bin/mysql /usr/bin/mysql
                ln -sf /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
                ln -sf /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
                ln -sf /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
                ln -sf /usr/local/mysql/bin/mysqlcheck /usr/bin/mysqlcheck
		}



php_make_install()
    {
          make -j `grep processor /proc/cpuinfo | wc -l`
             if [ $? -ne 0 ]; then
                  make
             fi
          make install
    }




function phpInstall()
		{
          local version="$1"
			    mkdir /tmp/php_build 
       		cd /tmp/php_build 
          cp -rf ${theFiledir}/php/*.tar.xz /tmp/php_build
  				yum install -y gcc-c++ libxml2-devel libxml2-devel libcurl-devel libcurl-devel \
          openssl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel 
  				groupadd -r www 
  				useradd -s /usr/sbin/nologin -r -M -N www 
  				tar Jxvf php-${version}.tar.xz
          cd php-${version}
  				./configure \
          --prefix=/usr/local/php-$version \
          --with-config-file-path=/usr/local/php-$version/etc \
          --bindir=/usr/local/php-$version/bin \
          --sbindir=/usr/local/php-$version/sbin \
          --enable-fpm --with-fpm-user=www \
          --with-fpm-group=www \
          --enable-mysqlnd \
          --with-mysqli=mysqlnd \
          --with-pdo-mysql=mysqlnd \
          --with-iconv-dir \
          --with-freetype-dir=/usr/local/freetype \
          --with-jpeg-dir \
          --with-png-dir \
          --with-zlib \
          --with-libxml-dir=/usr \
          --enable-xml \
          --disable-rpath \
          --enable-bcmath \
          --enable-shmop \
          --enable-sysvsem \
          --enable-inline-optimization \
          --with-curl \
          --enable-mbregex \
          --enable-mbstring \
          --with-gd \
          --with-openssl \
          --enable-pcntl \
          --enable-sockets \
          --with-mhash \
          --with-xmlrpc \
          --enable-zip \
          --enable-soap \
          --with-gettext \
          --disable-fileinfo \
          --enable-opcache
          php_make_install
          cp -rf ${theFiledir}/php/php-fpm-7.2.* /etc/init.d/
if [ ${version##*.} -eq 9 ]; then
cat > /usr/local/php-$version/etc/php-fpm.conf<<EOF
[global]
pid = /usr/local/php-7.2.9/var/run/php-fpm.pid
error_log = /usr/local/php-7.2.9/var/log/php-fpm.log
include=/usr/local/php-7.2.9/etc/php-fpm.d/*.conf
EOF
cat > /usr/local/php-$version/etc/php-fpm.d/www.conf<<EOF
[www]
user = www
group = www
listen=/usr/local/php-7.2.9/var/run/php-7.2.9.sock
listen.owner = www
listen.group = www
listen.mode = 0660
pm = dynamic
pm.max_children = 200
pm.start_servers = 30
pm.min_spare_servers = 30
pm.max_spare_servers = 30
EOF
elif [ ${version##*.} -eq 12 ]; then
cat > /usr/local/php-$version/etc/php-fpm.conf<<EOF
[global]
pid = /usr/local/php-7.2.12/var/run/php-fpm.pid
include=/usr/local/php-7.2.12/etc/php-fpm.d/*.conf
EOF
cat > /usr/local/php-$version/etc/php-fpm.d/www.conf<<EOF
[www]
user = www
group = www
listen = 0.0.0.0:9000;
listen.owner = www
listen.group = www
listen.mode = 0660
pm = dynamic
pm.max_children = 128
pm.start_servers = 32
pm.min_spare_servers = 32
pm.max_spare_servers = 32
slowlog = /usr/local/php-7.2.12/var/log/php-slow.log
request_slowlog_timeout = 2
request_terminate_timeout = 30
EOF
fi
		}

  

jemalloc_make_install()
    {
          make -j `grep processor /proc/cpuinfo | wc -l`
          if [ $? -ne 0 ]; then
                  make
          fi
          make install 
    }    

redis_make_install()
    {
        make -j `grep processor /proc/cpuinfo | wc -l` MALLOC=/usr/local/jemalloc/lib 
        if [ $? -ne 0 ]; then
                  make
        fi
        make install PREFIX=/usr/local/redis
    }


function redisInstall()
    { 
       mkdir /tmp/redis_build 
       cd /tmp/redis_build
       cp -rf ${theFiledir}/redis/* /tmp/redis_build
       yum install -y gcc-c++ bzip2 
       tar jxvf jemalloc-5.1.0.tar.bz2 
       tar zxvf redis-4.0.11.tar.gz 
       cd /tmp/redis_build/jemalloc-5.1.0 
        ./configure --prefix=/usr/local/jemalloc 
        jemalloc_make_install
        cd /tmp/redis_build/redis-4.0.11 
        tar zxvf redis-4.0.11.tar.gz 
        redis_make_install
        ln -sf /usr/local/redis/bin/redis /usr/bin/redis
       # sed -i '$a PATH=/usr/local/redis/bin:$PATH' /etc/profile && source /etc/profile
        echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf 
        echo " net.core.somaxconn= 4096" >> /etc/sysctl.conf 
        echo never > /sys/kernel/mm/transparent_hugepage/enabled 
        sysctl -p
        cp -rf ${theFiledir}/redis/redis /etc/init.d/
        mkdir -p /usr/local/redis/etc
        cp -rf ${theFiledir}/redis/redis.conf /usr/local/redis/etc/redis.conf

    }

 
function mongodbInstall()
    {
        cp -rf ${theFiledir}/mongodb/mongodb-linux-x86_64-4.0.10.tgz /opt
        cd /opt && tar -xvf mongodb-linux-x86_64-4.0.10.tgz
        mv mongodb-linux-x86_64-4.0.10 mongodb 
        cd mongodb
        mkdir -p /data/mongodb
        mkdir /opt/mongodb/logs
        cp -rf ${theFiledir}/mongodb/mongod /etc/init.d/mongod
        chmod +x /etc/init.d/mongod
        ln -s /opt/mongodb/bin/mongo /usr/bin/mongo
cat > /etc/mongod.conf<<EOF
systemLog: 
   destination: file 
   path: "/opt/mongodb/logs/mongodb.log" 
   logAppend: true 
storage: 
   dbPath: "/data/mongodb" 
   journal: 
      enabled: true 
   mmapv1: 
     smallFiles: true 
   wiredTiger: 
      engineConfig: 
        configString: cache_size=345M 
processManagement: 
      fork: true 
net: 
   #bindIp: 127.0.0.1 
   port: 27017 
setParameter: 
   enableLocalhostAuthBypass: false
EOF
    }



function rocketmqInstall()
    {
      yum -y install unzip java
      cp -rf ${theFiledir}/rocketmq/rocketmq-all-4.3.2-bin-release.zip /opt
      cp -rf ${theFiledir}/rocketmq/rocketmq_broker /etc/init.d/
      cp -rf ${theFiledir}/rocketmq/rocketmq_srv /etc/init.d/
      cd /opt && unzip rocketmq-all-4.3.2-bin-release.zip
      mv /opt/rocketmq-all-4.3.2-bin-release /opt/rocketmq
      cd /opt/rocketmq
      sed -i 's/-Xms8g -Xmx8g -Xmn4g/-Xms512m -Xmx512m -Xmn512m/g' /opt/rocketmq/bin/runbroker.sh
      sed -i 's/15g/1g/g' /opt/rocketmq/bin/runbroker.sh
      sed -i 's/-Xms4g -Xmx4g -Xmn2g/-Xms1g -Xmx1g -Xmn1g/g' /opt/rocketmq/bin/runserver.sh
# cat > startSrv<<EOF
# nohup sh /opt/rocketmq-all-4.3.2-bin-release/bin/mqnamesrv -n IPADDR:9876  >  ~/logs/rocketmqlogs/namesrv.log  & 
# tail -f ~/logs/rocketmqlogs/namesrv.log
# EOF
# cat > startBroker<<EOF
# nohup sh /opt/rocketmq-all-4.3.2-bin-release/bin/mqbroker -n  IPADDR:9876  >  ~/logs/rocketmqlogs/broker.log   & 
# tail  -f  ~/logs/rocketmqlogs/broker.log
# EOF
# cat > stopSrv<<EOF
# sh /opt/rocketmq-all-4.3.2-bin-release/bin/mqshutdown namesrv
# EOF
# cat > stopBroker<<EOF
# sh /opt/rocketmq-all-4.3.2-bin-release/bin/mqshutdown broker
# EOF
      # if [ -f startSrv -a -f startBroker -a -f stopSrv -a -f stopBroker ];then
      #   sed -i 's/IPADDR/'${localIP}'/g' /opt/rocketmq-all-4.3.2-bin-release/startSrv
      #   sed -i 's/IPADDR/'${localIP}'/g' /opt/rocketmq-all-4.3.2-bin-release/startBroker
      # else 
      #   echo -e "\033[31;49;1m[`date +%F' '%T`] Error: rocketmq have some error, please check it\033[39;49;0m"
      #   exit 0
      # fi
      sed -i 's/IPADDR/'${localIP}'/g' /etc/init.d/rocketmq_broker
      sed -i 's/IPADDR/'${localIP}'/g' /etc/init.d/rocketmq_srv
      chmod +x /etc/init.d/rocketmq_broker /etc/init.d/rocketmq_srv
      mkdir -p /opt/rocketmq/logs/rocketmqlogs
      /etc/init.d/rocketmq_srv start
      /etc/init.d/rocketmq_broker start
      sh bin/mqadmin updateTopic -n ${localIP}:9876  -c DefaultCluster  -t SELF_TEST_TOPIC
      sh bin/mqadmin updateTopic -n ${localIP}:9876  -c DefaultCluster  -t ${localIP//./-}_deliver
      sh bin/mqadmin updateTopic -n ${localIP}:9876  -c DefaultCluster  -t ${localIP//./-} _handler
    }


function python3Install()
    {
        yum install gcc openssl-devel bzip2-devel libffi-devel -y
        mkdir -p /tmp/python3
        cp -rf ${theFiledir}/python/*.tar.xz /tmp/python3
        cd /tmp/python3
        tar xvJf Python-3.7.3.tar.xz
        cd Python-3.7.3
        ./configure
        make && make install
        ln -s /usr/local/bin/python3.7 /usr/bin/python3
        ln -s /usr/local/bin/pip3.7 /usr/bin/pip3
    }


function fastdfsInstall()
    {  
      yum install -y perl unzip gcc gcc-c++
      mkdir -p /opt/fastdfs
      cp -rf ${theFiledir}/fdfs/*.zip /opt/fastdfs
      cd /opt/fastdfs && unzip libfastcommon-master.zip
      unzip fastdfs-master.zip 
      cd libfastcommon-master/ 
      ./make.sh 
      ./make.sh install
      cd /opt/fastdfs/fastdfs-master
      ./make.sh 
      ./make.sh install 
      cd /etc/fdfs/
      mv client.conf.sample client.conf
      mv storage.conf.sample storage.conf
      mv tracker.conf.sample tracker.conf 
      mkdir -p /data/fdfs/tracker
      sed -i 's/base_path=\/home\/yuqing\/fastdfs/base_path=\/data\/fdfs\/tracker/g' /etc/fdfs/tracker.conf
      sed -i 's/store_group=group2/store_group=group0/g' /etc/fdfs/tracker.conf
      sed -i 's/group1/group0/g' /etc/fdfs/storage.conf
      sed -i 's/base_path=\/home\/yuqing\/fastdfs/base_path=\/data\/fdfs\/storage/g' /etc/fdfs/storage.conf
      sed -i 's/store_path0=\/home\/yuqing\/fastdfs/store_path0=\/data\/fdfs\/storage/g' /etc/fdfs/storage.conf
      sed -i 's/192.168.209.121/'${localIP}'/g' /etc/fdfs/storage.conf
      sed -i 's/tracker_server\ =\ 192.168.209.122\:22122/\#tracker_server\ =\ 192.168.209.122\:22122/g' /etc/fdfs/storage.conf
      ln -s /usr/bin/fdfs_trackerd /usr/local/bin/ 
      ln -s /usr/bin/stop.sh  /usr/local/bin
      ln -s /usr/bin/restart.sh  /usr/local/bin
      mkdir -p /data/fdfs/storage/
      ln -s /usr/bin/fdfs_storaged /usr/local/bin/ 
      service fdfs_trackerd start
      service fdfs_storaged start 

      check_nginx_run
      yum install -y pcre-devel unzip gcc gcc-c++ openssl openssl-devel
      cp -rf ${theFiledir}/nginx/master.zip /opt
      cp -rf ${theFiledir}/nginx/nginx-1.9.11.tar.gz /opt/fastdfs
      cp -rf ${theFiledir}/nginx/nginx /etc/init.d/
      yum install -y pcre pcre-devel zlib zlib-devel openssl openssl-devel
      cd /opt && unzip master.zip
      cd /opt/fastdfs && tar -xvf nginx-1.9.11.tar.gz
      cd nginx-1.9.11/
      ./configure\
       --prefix=/usr/local/nginx \
       --add-module=/opt/fastdfs-nginx-module-master/src \
       --with-http_ssl_module \
       --with-stream --user=nginx \
       --group=nginx            
      make && make install
      cp -rf ${theFiledir}/nginx/nginx.conf /usr/local/nginx/conf/nginx.conf
      mkdir -p /var/log/nginx
      mkdir -p /usr/local/nginx/conf/conf.d
      mkdir -p /etc/nginx/conf.d
      mkdir -p /data/fdfs/storage/group0/M00
      cp -rf ${theFiledir}/fdfs/fastdfs.conf /usr/local/nginx/conf/conf.d/fastdfs.conf
      ln -s /data/fdfs/storage/data/ /data/fdfs/storage/group0/M00
      cd /opt/fastdfs/fastdfs-master/conf
      cp anti-steal.jpg http.conf mime.types /etc/fdfs/
      cd /opt/fastdfs-nginx-module-master/src
      cp mod_fastdfs.conf /etc/fdfs/
      #sed -i '$i\include conf.d/*.conf;' /usr/local/nginx/conf/nginx.conf
      sed -i 's/base_path=\/tmp/base_path=\/data\/fdfs\/storage\//g' /etc/fdfs/mod_fastdfs.conf
      sed -i 's/tracker:22122/'${localIP}':22122/g' /etc/fdfs/mod_fastdfs.conf
      sed -i 's/group_name=group1/group_name=group0/g' /etc/fdfs/mod_fastdfs.conf
      sed -i 's/url_have_group_name = false/url_have_group_name = true/g' /etc/fdfs/mod_fastdfs.conf
      sed -i 's/store_path0=\/home\/yuqing\/fastdfs/store_path0=\/data\/fdfs\/storage/g' /etc/fdfs/mod_fastdfs.conf
cat >> /etc/fdfs/mod_fastdfs.conf<<EOF
[group0] 
group_name=group0 
storage_server_port=23000 
store_path_count=1 
store_path0=/data/fdfs/storage 
EOF
      service fdfs_storaged restart 
      service fdfs_trackerd restart 
      useradd -s /sbin/nologin -M nginx
      chmod +x /etc/init.d/nginx

    }


function nginxInstall()
    {
        check_nginx_run
       	yum install -y pcre-devel unzip gcc gcc-c++ openssl openssl-devel        
        cp -rf ${theFiledir}/nginx/nginx-1.17.9.tar.gz /opt/
        cp -rf ${theFiledir}/nginx/nginx /etc/init.d/
        groupadd nginx
        useradd -s /sbin/nologin -g nginx nginx
        cd /opt && tar -xvf nginx-1.17.9.tar.gz
       # cd /opt && tar -xvf nginx-1.9.11.tar.gz
        cd nginx-1.17.9/
        ./configure\
         --prefix=/usr/local/nginx \
         --with-http_ssl_module \
         --with-stream --user=nginx \
         --group=nginx
         make && make install
        cp -rf ${theFiledir}/nginx/nginx.conf /usr/local/nginx/conf/nginx.conf
        rm -rf /opt/nginx-1.17.9.tar.gz
        chmod +x /etc/init.d/nginx
        mkdir -p /var/log/nginx

    }


function sys_optimize()
    {
               echo -e "* soft  nproc 102400 \n*  hard  nproc 102400" >> /etc/security/limits.d/90-nproc.conf
               echo -e "* soft nofile 102400 \n* hard nofile 102400" >> /etc/security/limits.conf
               cp -rf ${theFiledir}/sys/sysctl.conf /etc/sysctl.conf
               chmod 644 /etc/sysctl.conf
               sysctl -p
               rm -rf /etc/localtime
               ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
               source /etc/profile
    } 


function all_run()
    {
        mysqlInstall
        /etc/init.d/mysql restart
        check_run mysql
        random_mysql_pwd=`cat /data/mysql/mysql-error.log|grep root@localhost|awk '{print $NF}'`

        phpInstall 7.2.9
        phpInstall 7.2.12
        /etc/init.d/php-fpm-7.2.9 start
        /etc/init.d/php-fpm-7.2.12 start
        check_run php

        redisInstall
        /etc/init.d/redis start
        check_run redis

        mongodbInstall
        /etc/init.d/mongod start
        check_run mongod

        fastdfsInstall
        service fdfs_storaged start 
        service fdfs_trackerd start
        check_run fdfs
        /etc/init.d/nginx start
        check_run nginx

        python3Install

        rocketmqInstall
        check_run rocketmq
    }



function main()
		{
			  init
        case "$1" in
            sysinit)
                sys_optimize
                ;;
            mysql)
                mysqlInstall
                /etc/init.d/mysql restart
                check_run mysql
                random_mysql_pwd=`cat /data/mysql/mysql-error.log|grep root@localhost|awk '{print $NF}'`
                ;;
            php)
                phpInstall 7.2.9
                phpInstall 7.2.12
                /etc/init.d/php-fpm-7.2.9 start
                /etc/init.d/php-fpm-7.2.12 start
                check_run php
                ;;
            redis)
                redisInstall
                /etc/init.d/redis start
                check_run redis
                ;;
            mongodb)
                mongodbInstall
                /etc/init.d/mongod start
                check_run mongod
                ;;
            fdfsnginx)
                fastdfsInstall
                service fdfs_storaged start 
                service fdfs_trackerd start
                check_run fdfs
                /etc/init.d/nginx start
                check_run nginx
                ;;
            nginx)
                nginxInstall
                /etc/init.d/nginx start
                check_run nginx
                ;;
            python3)
                python3Install
                ;;
            rocketmq)
                rocketmqInstall
                check_run rocketmq
                ;;
            all)
                prompt "are you sure install all this (sysinit|mysql|php|redis|mongodb|fdfsnginx|python3|rocketmq)"
                if [ $? == 0 ];then 
                  all_run
                else
                  exit 1
                fi
                ;;
            *)
                echo "Usage: $0 {sysinit|mysql|php|redis|mongodb|fdfsnginx|nginx|python3|rocketmq|all}"
                exit 1
                ;;
        esac  

        echo -e "\033[33m +------------------------------------------------------------------------+ \033[0m"
        echo -e "\033[33m |        * 系统初始化安装完成，请检查各个软件的启动情况 *                | \033[0m"
        echo -e "\033[33m +------------------------------------------------------------------------+ \033[0m"

        echo -e "\033[33m |          mysql数据库root用户生成的随机密码是 ${random_mysql_pwd}                    | \033[0m"
        echo -e "\033[33m |          请尽快登录mysql，并修改root密码                               | \033[0m"
        echo -e "\033[33m +------------------------------------------------------------------------+ \033[0m"
        echo " "
		}

main $*



