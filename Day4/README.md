# Day 4

---

### 材料
1. ImageBuilder。为了实现wifi的检测功能，我们需要安装一个额外的程序包，wireless-tools，给客制化的OpenWRT。

---
### 思路：同时开启AP与STA模式
1. 细心的朋友可能已经发现在Day3的内容当中，我们在将wifi模块连到一个热点上的同时，OpenWRT这个wifi模块本身的热点也会同时存在，所以我们已经把同时开启AP和STA的方法带到过了，这里着重提出一些细节上的问题。在此之前我想解释一下开启AP和STA的意图，当我们最后做完成品，这个带摄像头的wifi模块很可能会被放在天花板的角上或者一些平时够不到的地方，这样能保证镜头的视野。所以在这个时候如果我们相对wifi模块做一些更改的时候总不可能搬个梯子连着把网线连上去。于是乎AP模式就很有存在的必要了。那可能又有同学会问，我开着STA模式，不同样也可以ssh到wifi模块么！对的，没错，AP模式的作用可以被STA代替，但是如果家里的无线路由器不能正常工作了，或者改了一下密码，那STA模式不就会因为没有跟上它修改的新密码而失效。所以，说到底AP模式就是一个fail safe。一个方便我们操作的fail safe。
2. 一个棘手的问题，如果真的STA模式瘫痪了，可能原因有很多，最简单的就是wifi热点的密码换了。那么会有一个很尴尬的结果，AP模式跟着失效。我的理解就是如果wireless当中的设置错误，wifi命令就会一直停在错误位置。因为没有查到wifi命令的帮助文件，所以只是个猜测。那如何保证我们的AP模式一直存在呢？找到的一个替代[解决方案](https://wiki.openwrt.org/doc/recipes/ap_sta)，它的思路是先把只有AP模式的wireless文件以及AP+STA模式的wireless文件保存在OpenWRT内部，默认的wireless也是这个AP+STA的设置。当每次开机的时候检测是否有连上wifi热点，即STA模式是否工作正常，如果正常那AP模式也就自然没有问题，如果工作异常，它会自动将wireless的内容换作只有AP模式的配置。相当于发现STA模式不好使的时候，断一下wifi模块的电源，然后等它重启后的自动检测。这算是解决这个问题的一个很简单的思路，在下面步骤这节会具体实现。

---
### 步骤

1. 保存只有AP与AP+STA两种配置的wireless。我们首先将Day3当中的AP+STA的wireless通过`cp /etc/config/wireless /etc/config/wireless.ap+sta`保存到/etc/config/这个目录下，文件名叫wireless.ap+sta。内容如下
	```
	config wifi-device 'radio0'   
	        option type 'mac80211'
	        option hwmode '11g'               
	        option path 'platform/ar933x_wmac'
	        option htmode 'HT20'
	        option channel 'auto'
	                 
	config wifi-iface             
	        option device 'radio0'
	        option network 'lan'
	        option mode 'ap'     
	        option ssid 'OpenWrt'   
	        option encryption 'none'
	                           
	config wifi-iface 'station'   
	        option device 'radio0'
	        option network 'wwan'
	        option mode 'sta'   
	        option ssid 'some_ssid' 
	        option key 'some_key'             
	        option encryption 'some_encryption'
	```
接下来用`vim /etc/config/wireless`编辑，把最后station这个小节的config删除。再将这个AP only的设置方案保存到同一个目录下`cp /etc/config/wireless /etc/config/wireless.ap-only`。内容如下
	```
	config wifi-device 'radio0'   
	        option type 'mac80211'
	        option hwmode '11g'               
	        option path 'platform/ar933x_wmac'
	        option htmode 'HT20'
	        option channel 'auto'
	                 
	config wifi-iface             
	        option device 'radio0'
	        option network 'lan'
	        option mode 'ap'     
	        option ssid 'OpenWrt'   
	        option encryption 'none'
	```

2. 创建开机自动检测脚本。`cd /usr/bin/`，这个目录是默认属于系统环境目录，里面的程序可以自动被linux系统搜索到，然后`touch reboot_ap_sta_detect.sh`新建一个脚本文件。用vim去编辑它，内容是：
	```
	TIMEOUT=30
	SLEEP=3
	sta_err=0
	while [ $(iwconfig | grep -c "ESSID:off") -ge 1 ]; do
	   let sta_err=$sta_err+1
	   if [ $((sta_err * SLEEP)) -ge $TIMEOUT ]; then
	     cp /etc/config/wireless.ap-only /etc/config/wireless
	     wifi up
	     break
	   fi
	   sleep $SLEEP
	done
	```
这就是我们博文开篇提到的第一处写代码的部分咯，一个很简单的linux脚本，while循环内部每隔3秒去检测是否有wifi热点的连接，30秒之后还是没有检测到那就替换wireless为wireless.ap-only的设置。之后用`chmod +x reboot_ap_sta_detect.sh`给这个脚本可执行的权限。然后在系统的开机启动文件当中把这个脚本添加进去，`vim /etc/rc.local`，在exit 0这行之前加一行，内容是：reboot_ap_sta_detect.sh > /dev/null。值得注意的是，脚本里用于检测wifi状态的iwconfig程序，不在默认的客制化OpenWRT当中，所以称此机会回顾一下如何自定义OpenWRT固件吧。
3. 自定义固件与刷机。将wireless-tools，这款程序刷到固件内，然后将新的固件刷机回来。具体步骤请看Day2！这里只给出一个自定义固件的make语句：`make image PROFILE=TLWR703 PACKAGES="-ppp -ppp-mod-pppoe -kmod-ppp -kmod-pppoe -kmod-pppox -kmod-nf-ipt6 -kmod-nf-contrack6 -kmod-ipv6 -ip6tables -odhcp6c -libip6tc -kmod-ipv6 -firewall -iptables -odhcpc -kmod-ipt-conntrack -kmod-ipt-core -kmod-ipt-nat -kmod-nf-conntrack -kmod-nf-ipt -kmod-nf-nat -kmod-nf-nathelper -uhttpd -uhttpd-mod-ubus kmod-video-core kmod-video-uvc libpthread libjpeg mjpg-streamer wireless-tools"`。以及，注意用sysupgrade刷机的时候切忌不要加上-n这个属性，不然我们辛辛苦苦的设置文件就全没了！
4. 刷完机回来你会发现刚刚辛苦写的脚本不见了！是的，这就是刷机的作用。哈哈，这里故意放个小坑，就是为了再让你熟悉一次如何给OpenWRT添加一个开机自启动的脚本文件。所以重复一下第二步吧！然后用`cp /etc/config/wireless.ap+sta /etc/config/wireless` 把AP+STA模式的配置文件拷回去（默认不用的，因为刷机的时候不加-n属性就会保留所有之前的配置，这里保险起见加了这么一句），再用`vim /etc/config/wireless`故意把station部分的ssid改错，然后断电重启一下，看看这下我们的脚本是否会提供给我们一个AP呢！恭喜，今天的内容到这里结束辣！所有的配置文件啊脚本啊，都在[GitHub](https://github.com/fengxueem/Home_Surveillance)当中。

---
### 进阶
如果不熟悉Linux脚本的同学，可以以我们这个简单的脚本为例学习一下。[这里](https://linux.die.net/man/1/grep)是grep程序的用法，[这里](http://blog.csdn.net/doiido/article/details/43966819)是if以及while里面条件判断语句的用法。对于Linux的完整学习还推荐台湾作家蔡德明的《[鸟哥的私房菜](http://linux.vbird.org/linux_basic/)》，特别好，可惜有些内容有点旧了，毕竟这个行业发展迅速。

