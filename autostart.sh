#！/bin/bash


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
		sleep 1
		check_pid ${run_name}
		if [ $? -lt 1 ];then
			echo "${run_name} Failed to start successful, please check for right installation。exit"
			exit 0
		fi
	}

function main()
	{		
		check_pid mysql
		if [ $? -lt 1 ];then
			systemctl start mysqld
			check_run mysql
		fi
		check_pid php
		if [ $? -lt 1 ];then
			/usr/local/php-7.2.12/sbin/php-fpm
			/usr/local/php-storage-7.2.9/sbin/php-fpm
			check_run php
		fi
		check_pid nginx
		if [ $? -lt 1 ];then
			nginx
			check_run nginx
		fi
		check_pid fdfs
		if [ $? -lt 1 ];then
			service fdfs_storaged restart
			service fdfs_trackerd restart 
			check_run fdfs
		fi
		check_pid mongodb
		if [ $? -lt 1 ];then
			sh /opt/mongodb-3.4.0/start.sh
			check_run mongodb
		fi
		check_pid redis
		if [ $? -lt 1 ];then
			sh /opt/redis-4.0.1/start.sh
			check_run redis
		fi
		# check_pid rocketmq
		# if [ $? -lt 1 ];then
		# 	# sh /opt/rocketmq-4.3.2/startBroker
		# 	# sh /opt/rocketmq-4.3.2/startSrv
		# 	# check_run rocketmq

		# fi
		sleep 10
		check_pid netty
		if [ $? -lt 1 ];then
			sh /opt/netty/imchat-eureka/start.sh
			sh /opt/netty/imchat-deliver/start.sh
			sh /opt/netty/imchat-logicHandler/start.sh
			sh /opt/netty/upload/start.sh
		#	sh /opt/netty/test/start.sh

		#	sh /opt/netty/web/start.sh
		fi		
	}





main $*


