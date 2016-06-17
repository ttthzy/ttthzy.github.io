#! /bin/bash

#配置网络地址

INNER=127.0.0.1       #内网ip
OUTER=192.168.137.23  #外网ip


## 下载基础镜像

docker pull ttthzy/dinp_jenkins 
echo "1 jenkins"

docker pull ttthzy/dinp_redis 
echo "2 redis"

docker pull ttthzy/dinp_mysql 
echo "3 mysql"

docker pull ttthzy/dinp_memcached 
echo "4 memcached"

docker pull ttthzy/dinp_registry 
echo "5 registry"

docker pull ttthzy/dinp_ubuntu:12.04 
echo "6 ubuntu:12.04"

docker pull ttthzy/dinp_tomcat:8 
echo "7 tomcat:8"

docker pull ttthzy/dinp_golang:1.4
echo "8 golang:1.4"

docker pull ttthzy/dinp_uic
echo "9 dinp_uic"

docker pull ttthzy/dinp_builder
echo "10 dinp_builder"

docker pull ttthzy/dinp_scribe
echo "11 dinp_scribe"

docker pull ttthzy/dinp_server
echo "12 dinp_server"

docker pull ttthzy/dinp_dashboard
echo "13 dinp_dashboard"

docker pull ttthzy/dinp_agent
echo "14 dinp_agent"

docker pull ttthzy/dinp_router
echo "15 dinp_router"


#启动12个容器

echo "Registry"
docker run --name registry -d -v /root/dinp/data/registry:/tmp/registry -p 5000:5000 registry

echo "Jenkins"
docker run -d --name jenkins -p 8089:8080 -v /root/dinp/data/jenkins:/var/jenkins_home -v /usr/bin/docker/:/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock -u root jenkins

echo "Memcached"
docker run --name memcached -d memcached

echo "Redis"
docker run --name redis -d -p 6379:6379 redis

echo "Mysql"
docker run --name mysql -v /root/dinp/data/mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=toor -d mysql

echo "UIC"
docker run --name uic --link memcached:memcached --link mysql:mysql -e DB_NAME=uic -e DB_USER=root -e DB_PWD=toor -e UIC_TOKEN=123456 -d -p 8080:8080 uic

echo "Builder"
docker run -d --name dinp_builder --link mysql:mysql -e DB_NAME=builder -e DB_USER=root -e DB_PWD=toor -e UIC_URL=http://$OUTER:8080 -e UIC_TOKEN=123456 -e REGISTRY_URL=$INNER:5000 -p 7788:7788 -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker dinp_builder

echo "Scribe"
docker run -d --name scribe -p 1463:1463 -v /root/dinp/data/scribe:/tmp/scribetest scribe

echo "Server"
docker run -d --name dinp_server --link mysql:mysql --link redis:redis --link scribe:scribe -e DB_USER=root -e DB_PWD=toor -e DB_NAME=dash -e DOMAIN=dinp.5duozi.com -p 1980:1980 -p 1970:1970 dinp_server

echo "Dashboard"
docker run -d --name dinp_dash --link mysql:mysql --link memcached:memcached -e DB_NAME=dash -e DB_USER=root -e DB_PWD=toor -e UIC_URL=http://$OUTER:8080 -e UIC_TOKEN=123456 -e BUILDER_URL=http://$OUTER:7788 -e SERVER_URL=http://$INNER:1980 -e DOMAIN=dinp.5duozi.com -p 8082:8080 dinp_dashboard

echo "Agent"
docker run -d --name dinp_agent -e SERVER_HOST=$INNER -e SERVER_PORT=1970 -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -e AGENT_IP=$INNER dinp_agent

echo "Router"
docker run -d --name dinp_router --link redis:redis -p 8083:8082 -p 80:8888 index.tenxcloud.com/ttthzy/docker_dinp_router

