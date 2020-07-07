
# Day 6

---

### 材料
1. OpenWRT15.05系统的[SDK](https://downloads.openwrt.org/chaos_calmer/15.05/ar71xx/generic/)，用于编译ngrok的C语言版本客户端。
2. ngrokc的项目源码，在这个[github](https://github.com/dosgo/ngrok-c)中。

---
### 思路：wifi模块中搭建Ngrok客户端
1. 在上一天中，我们跟随leocode的教程生成过一个给Linux系统使用的ngrok的客户端版本，可是它太大，有11M多，而我又找到一个大神用C语言写好的版本，最后才52.7kb。所以长远考虑，选择使用c语言版本的。而且这个版本的使用和编译都相当简单。

---
### 步骤
1. 编译ngrokc。具体步骤请看原作者的[简书](http://www.jianshu.com/p/8428949d946c)，或者[github](https://github.com/dosgo/ngrok-c)。最后我们会得到一个名字是ngrokc的可执行文件。
2. 重新客制化OpenWRT固件，安装ngrokc的支持程序。ngrokc的支持程序有两个：libstdcpp和libopenssl。很不凑巧，这两个支持库也很大，所以需要客制化固件，而不能用opkg安装。具体的安装指令是`make image PROFILE=TLWR703 PACKAGES="-ppp -ppp-mod-pppoe -kmod-ppp -kmod-pppoe -kmod-pppox -kmod-nf-ipt6 -kmod-nf-contrack6 -kmod-ipv6 -ip6tables -odhcp6c -libip6tc -kmod-ipv6 -firewall -iptables -odhcpc -kmod-ipt-conntrack -kmod-ipt-core -kmod-ipt-nat -kmod-nf-conntrack -kmod-nf-ipt -kmod-nf-nat -kmod-nf-nathelper -uhttpd -uhttpd-mod-ubus kmod-video-core kmod-video-uvc libpthread libjpeg mjpg-streamer wireless-tools libstdcpp libopenssl`。抱歉辣，又要让刷机。没有一次性说明的原因就是希望学习曲线不会太陡。
3. 连接wifi热点。刷好我们这个最后版本的OpenWRT客制化系统之后，要像之前那样让它连接到家里的wifi热点，这样才能通过Internet连接到我们先前租的VPS。
4. 上传ngrokc到wifi模块。用`scp 存放ngrokc的目录/ngrokc root@192.168.1.1:/usr/bin/`将ngrokc传到wifi模块的/usr/bin/目录下，这样OpenWRT系统默认就可以找到它了。
5. 开启ngrokc。运行命令`ngrokc -SER[Shost:ngrok.你的域名,Sport:Day5中定义的http端口] -AddTun[Type:http,Lhost:127.0.0.1,Lport:8080,Sdname:自定义的次级域名]`就可以在wifi模块上开启ngrok客户端。到此为止，所有的ngrok相关的设置就结束了！恭喜，你已经可以在任意一台设备的浏览器中输入“你定义的域名:你定义的端口”去访问这个摄像头了！

---
### 进阶
做到这里我们的项目实质部分已经结束，最后都是细节的整理，怎样让它easy to use。所以这里我们需要好好整理一下自己的笔记，看看这几天的过程是如何的。今天的进阶内容就是复习开始以来到现在所有做过的工作。
