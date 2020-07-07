
# Day 5

---

### 材料
1.支持美金支付的信用卡

---
### 思路：解决如何将本地的live video服务推送到Internet中，实现任意网络位置都能查看live video
1. 首先不管是AP还是STA模式，我们的live video都仅仅是一个本地的http服务器，只有内网的用户才能访问到。没有公网ip的参与，我们是无法将live video放到Internet上的。我们最多能做的是，在入户网线的ip上做一个端口映射，将它的8080端口绑定到我们wifi模块ip的8080端口上，这样只要是用一个通信运营商的子网内部都可以访问到了，根据我大学好友所说，现在通信运营商布网的时候基本上都是一个住宅小区一个子网，很可能小区外面的同一个运营商的用户也访问不了。如果你想看一下自己的入户网线是不是在一个子网里面（基本一定是），可以在进户线连的路由器`看一下ip，如果是10.XXX.XXX.XXX或者192.168.XXX.XXX那就是在一个子网里头了。
2. 所以确定需要一个公网ip的参与，就很明白，租一个自己的VPS，买一个域名，自己的网站搞起！然后具体的我原先想得是学习一下mjpg-streamer的写法，在wifi模块上用C语言实现一个客户端，在VPS上用Java实现一个服务器，视频7/24有wifi模块推送到VPS上，然后在VPS上实现存储和响应查看请求。但是由于客观的需求，时间限制，和一个人的能力有限，这个方案被排除了。之后搜索到额花生壳与3322的DDNS（这个也需要我们的进户ip是一个公网ip），花生壳内网穿透。感觉这两个都不适合我们项目的需求，因为家庭摄像头，一方面安全因素，另一方面之后可能会有很多布置摄像头的需求，花生壳太贵。毕竟已经决定花钱买VPS，这就是一笔不小的开支。所以搜索了其他的内网穿透方案，发现一个很成熟的[ngrok](https://github.com/inconshreveable/ngrok)。它已经发展到2.0版本了，只可惜2.0是商用要钱。但是之前的版本还是放在github上供我们研究使用的。另外OpenWRT论坛上对ngrok的支持早就有大神实现了，所以水到渠成，决定采用ngrok。

---
### 步骤
1. 租用VPS。我选择DigitalOcean，因为它上面有很多现成的教程去设置一个服务器，还有promo code可以搜到，而且性价比其实和其他的差不多，最便宜的也是5美元一个月。具体租用过程请看我的这篇[博客](http://blog.csdn.net/u014795817/article/details/73865628)。
2. 购买域名。这里我们可以想办法省钱，阿里旗下的[万网](https://wanwang.aliyun.com/)是一个很不错的购买域名的平台，它上面时不时有优惠活动可以几块前买一个一年的域名。不过要注意的是，国内域名的购买是需要实名认证的，这个过程可能花半天到1天不等，所以决定要自己搭服务器之后就立马去买域名吧。然后需要将域名和VPS的ip钩连，第一步需要在万网的域名控制台修改DNS服务器，将这个域名注册到DigitalOcean的DNS服务器上，这样之后我们就不需要上万网，所有操作都在DigitalOcean上完成。DigitalOcean的DNS服务器是：ns1.digitalocean.com，ns2.digitalocean.com和ns3.digitalocean.com。然后回到DigitalOcean上给新建的VPS，add a domain。添加自己买的域名到A类型，同时再添加一个A类型的域名，名字是‘ngrok.你买的域名’，相当于在你买的域名最前面加一个ngrok.这个次级地址。它们俩指向的都是这个VPS的ip。另外CNAME一个‘*.ngrok.你买的域名’作为‘ngrok.你买的域名’的别名。这个A类型和CNAME类型的域名是为了给之后ngrok服务器使用的，详情见下一步。
3. 搭建ngrok服务器端。租用好服务器之后需要在上面做一些基本的学习工作，其实具体的操作也就是ssh啊，设置一下防火墙呀，之类的。可以参考我的[服务器软件安装记录](http://blog.csdn.net/u014795817/article/details/73912849)，里面写了如何搭建ngrok的服务器端。服务器端生成之后，就直接在服务器上跑起来吧！推荐在本地电脑也安装go语言，然后搭建ngrok服务器完成之后可以用go语言在本地计算机随便开一个http服务器，名字可以脚httpserver.go，内容如下
	```
	package main
	
	import "net/http"
	
	func main() {
	    http.HandleFunc("/", hello)
	    http.ListenAndServe(":8080", nil)
	}
	
	func hello(w http.ResponseWriter, r *http.Request) {
	    w.Write([]byte("hello!"))
	}
	```
	运行起来，然后从VPS上将生成的ngrok客户端用`scp admin_name@VPS_ip:/directory_to_ngrok_linux_client /usr/bin/`下载到本地/usr/bin/目录，之后可以根据[我的博文](http://blog.csdn.net/u014795817/article/details/73912849)里推荐的文章，去将本地的go语言http服务器推送到VPS上，如果成功的话，恭喜！今天的内容完成辣！你拥有了一个实现内网穿透的服务器！

---
### 进阶
虽然今天的步骤很短，那是因为大多数都是直接推荐了别的大神写的博文，实际上今天的工作量不小，所以请耐心完成基本部分，进阶内容为空。

