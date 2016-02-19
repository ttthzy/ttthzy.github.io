---
layout: post
title:  "实现thrift下http协议通讯"
permalink: /:categories/:title.html
date:   2016-02-19 13:42:31 +0800
categories: logs update
---



## 目标
----------
初学thrift，很想写一个基于http协议的接口例子，但由于网络上关于go-thrift http协议的教程和例子基本找不到，不得不动手摸索，经过一些坑后，掌握了thrift http协议的使用方法，本文仅限小白观看，大牛们请绕道。

- Golang写thrift服务端，Js写客户端。
- 用thirft构建简单的微服务组。
- 理解thrift各种数据传输格式。
- 尝试用thrift重构现有服务。


## 开发前准备（系统环境 windows2008）


#### 下载依赖包

    go get git.apache.org/thrift.git/lib/go/thrift


#### 定义IDL
    service UserStorage
    {
         i32 Sum( 1: i32 arg_number1, 2: i32 arg_number2),
         string GetString()
    }

#### 生成库文件

下载开发库编译器

[http://www.apache.org/dyn/closer.cgi?path=/thrift/0.9.3/thrift-0.9.3.exe](http://www.apache.org/dyn/closer.cgi?path=/thrift/0.9.3/thrift-0.9.3.exe "下载开发库编译器")

    //请将下载的exe文件放到系统环境变量path里，然后在cmd窗口执行如下命令
    thrift-0.9.3.exe  -gen go UserStorage.thrift
    thrift-0.9.3.exe  -gen js UserStorage.thrift
    //这里注意，生成的 user_storage-remote 文件夹仅仅是一个示例，没什么作用。 


## 编码实现（go服务端+js客户端）

#### golang实现服务端

    package main
    
    import (
    	rpc "thrift.go/userinfo"
    	"fmt"
    	"git.apache.org/thrift.git/lib/go/thrift"
    	"net"
    	"net/http"
    	"sync/atomic"
    	"golang.org/x/net/netutil"
    	"runtime"
    )
    
    ////////////////////////////////////////
    ////通过IDL定义的UserStorage接口实现 Start
    ////////////////////////////////////////
    type UserStorage struct {
    }
    
    func (this *UserStorage) Sum(arg_number1 int32, arg_number2 int32) (r int32, err error){
    	result := arg_number1 + arg_number2;
    	return result,nil;
    }
    
    var Counter int32
    func (this *UserStorage) GetString() (r string, err error){
    	Counter := atomic.AddInt32(&Counter,1)
    	return "thrift is OK : " +  fmt.Sprintf("%d",Counter),nil;
    }
    
    ////////////////////////////////////////
    //// End
    ////////////////////////////////////////

    func main() {
    	var processor = thrift.NewTMultiplexedProcessor()
    
    	inProtocolFactory := thrift.NewTJSONProtocolFactory()
    	outProtocolFactory := thrift.NewTJSONProtocolFactory()
    
    	processor.RegisterProcessor(
    		"UserStorage",
    		rpc.NewUserStorageProcessor(&UserStorage{}),
    	)
    
    	thriftHandlerFunc:=thrift.NewThriftHandlerFunc(processor,inProtocolFactory,outProtocolFactory)
    
    	http.HandleFunc("/thrift", thriftHandlerFunc)
    
    	http.ListenAndServe(":9388",nil)
    }



#### JS客户端准备

下载 thrift js包（如果无法下载，可以进你的gopath对应目录里找）

[http://git.apache.org/thrift.git/lib/js/src/thrift.js](http://git.apache.org/thrift.git/lib/js/src/thrift.js "获取thrift js包")

     根据前面生成的gen-js目录下，找到 UserStorage.js 等文件。
     编写一个简单的html，实现js客户端访问服务端。

#### JS客户端实现

    <script type="text/javascript" src="/js/jquery-1.9.1.min.js"></script>
    <script type="text/javascript" src="/js/thrift.js"></script>
    <script type="text/javascript" src="/js/UserStorage_types.js"></script>
    <script type="text/javascript" src="/js/UserStorage.js"></script>

    <script>

        var client1;
        $(document).ready(function () {
            var debugPosation = 0;
            try {

                //这里用到了thrift 9.0以后的多服务支持特性
                var mp = new Thrift.Multiplexer(); 
                var transport = new Thrift.Transport("http://127.0.0.1:9388/thrift");
                var protocol = new Thrift.Protocol(transport);
                client1 = mp.createClient('UserStorage', UserStorageClient, transport);

            } catch (e) {
                alert(e.message);
            }
        });


        ///客户端异步 远程调用服务端方法 GetString
        function GetString() {
            client1.GetString(function (data) {
                        console.log(data);
                    }
            );
        }

        ///客户端异步 远程调用服务端方法 Sum
        function Sum() {
            client1.Sum(100,5,function (data) {
                        console.log(data);
                    }
            );
        }

    </script>


## 总结

    thrift可以很方便统一前后端接口及model，对拆分或重构老系统是有一定帮助的。
    thrift用来开发微服务应该是很不错的选择。当然我也是刚入门，对于它的理解很有限。


----------

本人博客文章采用CC [Attribution-NonCommercial](https://creativecommons.org/licenses/by-nc-sa/3.0/ "Attribution-NonCommercial")协议: CC Attribution-NonCommercial 必须保留原作者署名,并且不允许用于商业用途,其他行为都是允许的。

----------


[jekyll-docs]: http://jekyllrb.com/docs/home
[jekyll-gh]:   https://github.com/jekyll/jekyll
[jekyll-talk]: https://talk.jekyllrb.com/


    