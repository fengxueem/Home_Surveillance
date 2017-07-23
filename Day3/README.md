# Day 3

---

### 材料
无

---

### 思路：wifi模块加入wifi热点（简称STA模式）
1. 因为最终我们的网络摄像头会部署在一个有wifi的环境当中，比如家里，办公室，等等。所以我们必须了解如何将wifi模块连入这些热点当中。其实有心的同学在第一天学习AP模式的时候看掉了进阶里面提到的/etc/config/wireless设置的话，对接下来我们需要完成的任务就不至于太陌生了。
2. 由于我们的wifi模块可以使用有线连接，也可以无线，无线又可以分成AP与STA，当然所以对于每一种接入模式我们都需要在网卡上定义一个逻辑的网络接口，用于区分彼此。每一个逻辑网络接口中会定义这个网络接口的ip的分配方式，使用的物理接口，等等。这是OpenWRT网络设置的核心部分，具体的文件就是/etc/config/network。可见/etc/config/这个目录底下就是专门存放这种软件的设置文件，之后我们还会学习到一个linux命令专门用来修改这个目录底下的文件。所以想要连接wifi那就必须先在network这个配置文件里面创建一个逻辑网络接口，并且标明这个网络接口的ip，dns之类的都是通过dhcp分配的，因为一般我们遇到的wifi热点都是用DHCP的，所以这里就不考虑特殊情况了。如果你的实验环境要求wifi热点的ip是静态的，那请看今天进阶部分的内容，会给一些参考资料供研究。

---
### 步骤

1. ssh连接wifi模块。当然我们这里选择用网线比较方便，因为如果用AP的话，等一下由于要更改wireless的设置，会重启wifi，这样AP会在重启的时候自动断掉，这里推荐用有线连接。

2. 修改wireless。用`vim /etc/config/wireless`进入编辑界面，在最下面加入（其实在哪加都一样，只要是自成一段就好。你可以放在中间的已有段落后面）
	```
	config wifi-iface station     
	        option device radio0
	        option network wwan
	        option mode sta
	        option ssid 你家的ssid
	        option encryption 对应的加密方式一般都是psk，psk2或wep
	        option key wifi密码
	```
wifi-iface后面跟的station是我们给这个wifi-iface小节取得名字，方便以后修改。里面根据自家情况需要变化的部分是ssid，encryption和key。其中不太明显的是encryption，加密方式。如果自己家新买无线路由器的时候有配置过路由器的同学会知道，wifi密码的加密方式也是分种类的，同一个字符串，比如‘12345678’，在不同的加密方式下面会有不同的验证密码的手段。一般无线路由器里面的加密方式会选用WPA或者WPA2又或是WEP。所以WPA对应的encryption是psk,WPA2对应的是psk2，WEP对应的是wep。除了这个各家各情况的三个部分，还有一个network，我们给的值是wwan，这就是思路里面提到的逻辑网络接口。我们在下面一步会在/etc/config/network中写明这个接口，这里的wwan也是个名字，我们称接下来新建的逻辑网络接口名叫wwan。

3. 添加逻辑网络接口wwan。之前说了这么高大上的逻辑网络接口，又是核心咯，又是关键咯，其实设置起来超级超级简单。用`vim /etc/config/network`打开编辑。同样在最下面，或者中间的某处添加：

	```
	config interface 'wwan'	
		option	proto	'dhcp'
	```
这样一来这个wwan逻辑接口就会调用OpenWRT里由busybox这款软件提供的udhcpc命令去接收并且设置自己的ip辣。

4. 重启wifi。`wifi down` 然后再`wifi`。之后使用`ifconfig`看一下各个网卡物理接口的具体情况，找到wlan0这个网卡接口，注意哦，这里不是逻辑接口了！而是实实在在的网卡！如果看到inet addr:192.168.0.10  Bcast:192.168.0.255  Mask:255.255.255.0这三个字段（ip，广播地址，子网掩码），你就可以确定已经连上wifi热点辣！

5. 用同样连上这个热点的手机，打开浏览器，网址栏输入你的wifi模块的ip:8080，就实现了在本地局域网里查看摄像头的视频咯，不用再连上wifi模块提供的热点辣。比如我的wifi模块ip是192.168.0.10，那我就在网址栏里输入192.168.0.10:8080。不连wifi模块自己的OpenWRT热点，好处就是能用手机看摄像头的视频，又能聊微信。酷吧！下一个大目标就是想办法把我们假设的摄像头视频服务推到Internet上面，实现我在哪上网都能看到摄像头视频！

---
### 进阶
[这里](https://wiki.openwrt.org/doc/uci/network)就是关于network这个配置文件的设置。

---
