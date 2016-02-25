---
layout: post
title:  "用docker构建AspNet5应用"
permalink: /:categories/:title.html
date:   2016-02-25 12:00:00 +0800
categories: logs update
---



## 目标
----------
因为做.net开发很多年，自从接触docker以来，一直都很想把aspnet部署到docker上，但因为种种原因想法拖延至今。在痛下决心后，经过数次踩雷踩坑，终于让aspnet成功上云。

- 熟悉linux下的aspnet5开发环境部署。
- 将一个aspnet5应用通过docker快速部署到云端。


## 准备（系统环境 Ubuntu 14）


#### 安装最新版docker

使用 apt-get

     sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
     sudo sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
     sudo apt-get update
     sudo apt-get install lxc-docker

手工安装

     killall docker
     wget http://get.docker.io/builds/Linux/x86_64/docker-latest -O docker
     chmod +x docker
     sudo ./docker -d &

都是一些常用指令，不过多说明了，有问题可自行google。



#### 安装aspnet5开发环境
这将是一个漫长的过程，没耐心嫌麻烦的的请止步。

1、安装DNVM

     sudo apt-get install unzip curl
     curl -sSL https://raw.githubusercontent.com/aspnet/Home/dev/dnvminstall.sh | DNX_BRANCH=dev sh && source ~/.dnx/dnvm/dnvm.sh
     source ~/.dnx/dnvm/dnvm.sh

     //安装完毕后，输入dnvm看下是否安装正确

2、使用DNVM安装DNX

     sudo apt-get install libunwind8 gettext libssl-dev libcurl4-openssl-dev zlib1g libicu-dev uuid-dev
     dnvm upgrade -r coreclr

     // 安装最新版 mono
     apt-key adv --keyserver keyserver.ubuntu.com –recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
     echo "deb http://download.mono-project.com/repo/debian wheezy main" |  tee /etc/apt/sources.list.d/mono-xamarin.list
     apt-get update
     apt-get install Mono-Complete

     // 安装DNX for Mono
     dnvm upgrade -r mono



3、安装libuv（kestrel）

这是微软提供的一个web容器，可用来测试或独立部署web应用。github上的地址附上：

      https://github.com/libuv/libuv
      https://github.com/aspnet/KestrelHttpServer

下面是安装指令

      sudo apt-get install make automake libtool curl
      curl -sSL https://github.com/libuv/libuv/archive/v1.8.0.tar.gz | sudo tar zxfv - -C /usr/local/src
      cd /usr/local/src/libuv-1.8.0
      sudo sh autogen.sh
      sudo ./configure
      sudo make
      sudo make install
      sudo rm -rf /usr/local/src/libuv-1.8.0 && cd ~/
      sudo ldconfig


#### 开发环境到这就部署完毕了，接下来是开发工具

根据微软官方推荐有4个工具可选，这里根据个人喜好，我用yo作为开发工具演示，当然vscode也是必不可少的

1、安装最新版nodejs

   请注意，nodejs版本太低装不了yo，所以请自行升级到最新版。如果升级过程中踩坑的话，建议直接从官方下载最新的编译包或者源码自行编译。

2、安装yo （不推荐用root用户安装，否则会遇到不少坑）

     // 通过npm包管理器安装yo
     npm install -g yo

     // 安装aspnet模板库
     npm install -g generator-aspnet

     //最后
     yo aspnet

3、至此就可以通过yo建立aspnet5项目了。


## 构建 aspnet docker image

1、用yo生成一个aspnet的webapi项目，注意目录对应第四步

2、docker pull microsoft/aspnet

3、如果你网络无障碍的话，就直接 docker build . ，第二步只为被墙的兄弟准备。

4、通过第二步的，生成容器并将卷映射至宿主机：

      docker run -i -t -p 22 -p 5000:5000 -v /root/aspnet5:/code  microsoft/aspnet:latest /bin/bash

5、宿主机访问5000端口测试api接口即可。

6、一个完整的dockerfile：

```
### My_AspNet5_Docker_Image
### 80186658@qq.com

FROM debian:jessie

ENV DNX_VERSION 1.0.0-beta8
ENV DNX_USER_HOME /opt/dnx

RUN apt-get -qq update && apt-get -qqy install unzip curl libicu-dev libunwind8 gettext libssl-dev libcurl3-gnutls zlib1g && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/aspnet/Home/dev/dnvminstall.sh | DNX_USER_HOME=$DNX_USER_HOME DNX_BRANCH=v$DNX_VERSION sh
RUN bash -c "source $DNX_USER_HOME/dnvm/dnvm.sh \
	&& dnvm install $DNX_VERSION -alias default -r coreclr \
	&& dnvm alias default | xargs -i ln -s $DNX_USER_HOME/runtimes/{} $DNX_USER_HOME/runtimes/default"

# Install libuv for Kestrel from source code (binary is not in wheezy and one in jessie is still too old)
# Combining this with the uninstall and purge will save us the space of the build tools in the image
RUN LIBUV_VERSION=1.4.2 \
	&& apt-get -qq update \
	&& apt-get -qqy install autoconf automake build-essential libtool \
	&& curl -sSL https://github.com/libuv/libuv/archive/v${LIBUV_VERSION}.tar.gz | tar zxfv - -C /usr/local/src \
	&& cd /usr/local/src/libuv-$LIBUV_VERSION \
	&& sh autogen.sh && ./configure && make && make install \
	&& rm -rf /usr/local/src/libuv-$LIBUV_VERSION \
	&& ldconfig \
	&& apt-get -y purge autoconf automake build-essential libtool \
	&& apt-get -y autoremove \
	&& apt-get -y clean \
	&& rm -rf /var/lib/apt/lists/*


# 设置SSH服务中终端的超时时间或不超时
RUN echo 'ClientAliveInterval 120' >> /etc/ssh/sshd_config && \
echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config

# 设置数据卷
RUN mkdir -p /code/
VOLUME /code/
WORKDIR /code/

ENV PATH $PATH:$DNX_USER_HOME/runtimes/default/bin

```




## 遇到的坑

      bash: kestrel: command not found

经过数次踩坑经验，如果出现以上错误，大致可能因为project.json文件里版本号不匹配，dnvm list对一下运行时的版本号。终极解决大发可以这样：

      比如版本号是：1.0.0-rc1-update1
      直接写成：1.0.0-*

如果镜像构建失败，不要找原因了，妥妥的是网络被墙，解决办法是通过dockerhub构建，这里推荐用时速云的国际节点。


yo如果出现如下提示：

      Error: EACCES, permission denied '/root/.config/configstore/insight-yo.yml'
      You don't have access to this file.

      // 网上搜了各种找不到答案，后来终于在一些其他问题的解决办法中悟到，是因为在root下安装造成的，可通过如下方式解决：
      mkdir /root/.config/configstore
      chmod g+rwx /root /root/.config /root/.config/configstore


## 总结

    本地开发并部署aspnet至docker并非一件容易的事，微软因为版本问题带给我们很多坑。
    下一篇文章将研究一下aspnet5与docker接合后的优势及aspnet5特性。


----------

本人博客文章采用CC [Attribution-NonCommercial](https://creativecommons.org/licenses/by-nc-sa/3.0/ "Attribution-NonCommercial")协议: CC Attribution-NonCommercial 必须保留原作者署名,并且不允许用于商业用途,其他行为都是允许的。

----------


[jekyll-docs]: http://jekyllrb.com/docs/home
[jekyll-gh]:   https://github.com/jekyll/jekyll
[jekyll-talk]: https://talk.jekyllrb.com/
