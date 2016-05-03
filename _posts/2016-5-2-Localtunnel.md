---
layout: post
author: ttthzy
title:  "Localtunnel内网穿透工具的安装与使用"
permalink: /:categories/:title.html
date:   2016-05-02 09:30:00 +0800
categories: logs update
---


#### 简介

Localtunnel可以方便快捷的实现你的本地web服务通过外网访问，无需修改DNS和防火墙设置，其实原理与ngrok类似。但Localtunnel是基于nodejs的，而ngrok是基于go语言。

源码地址
<https://github.com/localtunnel/localtunnel>

#### 使用官方提供的Localtunnel服务端

##### 安装localtunnel客户端

localtunnel是基于node.js的一个模块，所以首先需要安装node.js和npm。(此部分略)

     $npm install -g localtunnel

##### 使用

假设本地服务器在81端口，我们可以通过下面的命令把本地服务器暴露到公网中

     $lt --port 81
     your url is: https://ouumalrvoi.localtunnel.me
    
通过上面的命令，我们不需要做其他设置就可以通过https://ouumalrvoi.localtunnel.me来访问我们本地服务器了。

如果想通过固定的域名访问，则可以通过以下命令进行设置，成功后可通过https://mike.localtunnel.me而访问到本地服务器。

     $lt --subdomain mike --port 81
     $lt -s mike -p 81
     
#### 自建Localtunnel服务端

由于localtunnel.me是国外的服务器，访问速度有时候不太理想，这时候我们可以自己搭建localtunnel的服务端。

##### 安装服务端

     $git clone https://github.com/localtunnel/server.git localtunnel-server
     $cd localtunnel-server
     $npm install
##### 使用

以监听2000端口为例：

##### 直接使用

     $bin/server --port 2000
     localtunnel server listening on port: 2000 +0ms
     
##### 配合pm2使用

安装pm2

     $npm install -g pm2

运行

     $pm2 --name lt start bin/server -- --port 2000
     
启动服务端程序后，我们只要在使用客户端lt时加上–host参数，就可以指定服务端了。

host后面不要加/

     $lt --host http://imike.me:2000 --port 81
     your url is: http://imike.me:2000
     
这样，我们就可以通过自己的代理服务器来访问本地服务器了，不用经过第三方代理服务器，不必担心代理服务器的安全问题。

#### 高级用法

##### 反向代理

在Github 上面有一份Nginx的配置，我们可以直接使用，或者按照自己的需要做些修改。

```
proxy_http_version 1.1;

# http://nginx.org/en/docs/http/websocket.html
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

upstream lt-server {
    server 127.0.0.1:2000;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    server_name .localtunnel.me;

    location / {
        proxy_pass http://lt-server/;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Proto http;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        proxy_redirect off;
    }
}

server {
    listen 443 default_server ssl spdy;
    listen [::]:443 default_server ipv6only=on;

    server_name .localtunnel.me;

    ssl on;

    ssl_certificate      /etc/nginx/ssl/STAR.localtunnel.me.crt;
    ssl_certificate_key  /etc/nginx/ssl/STAR.localtunnel.me.key;

    ssl_protocols              SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers                RC4:HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers  on;

    ssl_session_cache    shared:SSL:10m;
    ssl_session_timeout  10m;

    location / {
        proxy_pass http://lt-server/;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header Connection $connection_upgrade;

        proxy_redirect off;
    }
}

```

##### 指定子域名

有时候，用随机字符串作为子域名并不是一件好事，我们可能需要固定的域名来访问本地服务器。这时，lt –subdomain就可以派上用场了。

subdomain限制长度为4 ~ 63

     $lt --host http://tunnel.imike.me:2000 --port 81 --subdomain mysubdomain
     your url is: http://mysubdomain.tunnel.imike.me:2000
     
看到了吗？通过–subdomain，我们就可以指定自己喜欢的子域名了。

然而，如果我们通过–host来指定子域名，会发生什么？

     $lt --host http://tunnel.imike.me:2000 --port 81
     Error: localtunnel server returned an error, please try again
     
就算配置了 Nginx 的反向代理，你依然会得到这个错误。

要解决这个问题，最简单的就是不用–host来指定子域名，而用–subdomain来指定。


----------

本人博客文章采用CC [Attribution-NonCommercial](https://creativecommons.org/licenses/by-nc-sa/3.0/ "Attribution-NonCommercial")协议: CC Attribution-NonCommercial 必须保留原作者署名,并且不允许用于商业用途,其他行为都是允许的。

----------


[jekyll-docs]: http://jekyllrb.com/docs/home
[jekyll-gh]:   https://github.com/jekyll/jekyll
[jekyll-talk]: https://talk.jekyllrb.com/
