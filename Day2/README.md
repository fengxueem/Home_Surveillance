# Day 2

---

### 材料
1. 客制化OpenWRT固件工具：ImageBuilder，单击[此处](https://downloads.openwrt.org/chaos_calmer/15.05/ar71xx/generic/OpenWrt-ImageBuilder-15.05-ar71xx-generic.Linux-x86_64.tar.bz2)下载。解压在你喜欢的本地目录当中，我们称解压之后的ImageBuilder的目录为**A目录**，里面应该包含有：include, packages, scripts, target等等的目录以及.config, .targetinfo, Makefile, rules.mk等文件。**A目录**就是我们之后经常要在里面进行客制化OpenWRT的场所了。
2. 支持mjpg格式输出的摄像头一枚，某宝上可以买到，40rmb左右。另外如果自己家有老的摄像头也可以拿来看看是不是支持mjpg输出。请看这个[博文](http://blog.csdn.net/u014795817/article/details/75652496)，学习一下如何用linux查看usb摄像头的基本信息，看看你的老摄像头是不是支持mjpg。这里必需要支持mjpg的原因是，首先jpg格式的图片是压缩过的图片，用的压缩算法又很经典，所以用mjpg传输图像要省流量，但是mjpg的压缩是需要很大计算量的！所以如果摄像头不支持mjpg的输出，只能靠wifi模块的CPU去进行格式转换，那就呵呵了，算死这个CPU，真的会算爆它的，因为我们选用的设备额定工作温度40摄氏度一下。所以安全起见，实在没有mjpg的摄像头，那还是先停一下实战，买一个再说。

---

### 思路：在局域网中开启mjpg-streamer服务，并用其他加入该局域网的设备查看live video
1. Mjpg-Streamer是一个开源项目，其基本功能是从一个uvc内核摄像头读取内容，然后将它推送到本地的8080端口上面。就是一个本地的视频服务器。它的项目网站在[这里](https://sourceforge.net/projects/mjpg-streamer/)。OpenWRT的软件源中也已经对它有了移植，所以我们只需要从OpenWRT的官方网站上找到对应15.05版本OpenWRT系统的Mjpg-Streamer，然后下载安装即可。除此之外还需要一些其他的软件包去支持它的运行：kmod-usb-core, kmod-usb2, kmod-video-core, kmod-video-uvc, libpthread, libjpeg。前4个是linux的系统内核文件，相当于usb接口和摄像头的驱动;后2个是库文件，用与提供多线程和jpeg图片格式支持。
2. 在第一天的内容当中提到过，由于这次选用的wifi模块的Flash（SquashFS）特别小！所以我们在安装Mjpg-Streamer的方法会很特别，不会是用OpenWRT默认的opkg这款软件进行安装下载，因为opkg的安装方式会消耗很多不必要的Flash空间，其直接结果就是装了几个额外的软件之后就没有剩余空间。所以我们采用客制化OpenWRT固件的方式，将需要的软件直接写到OpenWRT的固件当中，这样极其节省空间，而且还可以删去和本次项目没有关系的一些默认安装的软件，以达到系统精简的目的。

---

### 步骤
1. 客制化OpenWRT固件。请先看我的这篇[博文](http://blog.csdn.net/u014795817/article/details/74505666)，去大致了解一下客制化固件，里面有推荐官方的wiki文档和其他一些准备内容，记得看完之后再接下去操作！如上所述。为了安装mjpg-streamer和之后的一些内容，我们需要将一些不需要的软件包删除，并安装必要的包。首先在本地电脑上打开terminal，然后`cd A/`，进入到A目录下。输入`make image PROFILE=TLWR703 PACKAGES="-ppp -ppp-mod-pppoe -kmod-ppp -kmod-pppoe -kmod-pppox -kmod-nf-ipt6 -kmod-nf-contrack6 -kmod-ipv6 -ip6tables -odhcp6c -libip6tc -kmod-ipv6 -firewall -iptables -odhcpc -kmod-ipt-conntrack -kmod-ipt-core -kmod-ipt-nat -kmod-nf-conntrack -kmod-nf-ipt -kmod-nf-nat -kmod-nf-nathelper -uhttpd -uhttpd-mod-ubus kmod-video-core kmod-video-uvc libpthread libjpeg mjpg-streamer"`，之后程序就会自动进行客制化固件的过程了，视网络情况不同，客制化的花费时间也不同，我这里用中国移动的20MB宽带几分钟就完成了。至于命令为什么这么写，就在官方wiki中有解释，所以这部分基础内容不重复了，再强调一下为了扎实的前进，花时间去看一下我的博文和里面所提到的wiki。值得注意的是在ImageBuilder当中默认的软件里就不带luci，所以我们不用额外删除它咯！当然Day 1当中提到的官方固件里面是默认包括luci的。
2. 刷机。将第一步当中A目录下的bin/ar71xx/下生成的固件，‘openwrt-15.05-ar71xx-generic-tl-wr703n-v1-squashfs-factory’，刷入我们的wifi模块，方法就是第一天中提到的刷机方式，《[OpenWRT刷机入门](http://blog.csdn.net/u014795817/article/details/74504791)》。这里可能会有疑问，为什么不一步到位直接让我们刷最终版本的固件呢？因为重复的练习，会让我们更加清楚自己在做什么。毕竟这篇博文的目的不仅仅是一篇HowTo，更加重要的是对问题的理解和处理问题的方式。好了这里就提一个新的需要注意的细节，在《[OpenWRT刷机入门](http://blog.csdn.net/u014795817/article/details/74504791)》的初级办法当中我们实际上用的`sysupgrade /tmp/openwrt-15.05.1-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin`这条命令进行刷机，那有心的小伙伴也许会有担心说我们Day 1当中更改了一下系统的设置，刷机之后这个设置还会保留吗？答案：会保留。在sysupgrade命令当中如果加入-n这个选项，那么一些的设置都会被reset，所以当我们发现自己改着改着系统不知道哪里被玩坏了之后，请记得在刷机的时候用带n选项的sysupgrade就可以了，这里给一个例子： `sysupgrade -n /tmp/openwrt-15.05.1-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin`。所以，我们默认是保留设置的，Day 1当中已经给OpenWRT的root用户设置了密码，开启了ssh登录方式，以及AP模式，在刷机完成之后，这一切都会被保留，是不是很赞！
3. 将用户设备连入wifi模块提供的热点。用手机或者电脑连接，wifi模块的热点中。这样我们的用户设备会自动的被分配到一个ip，这个ip和wifi模块的ip属于同一个网段。我们假设是用电脑连接的，打开terminal，用`ssh root@192.168.1.1`链接到wifi模块。如果做到这里你发现搜不到wifi模块的热点，不用着急，我们这里的目的只是为了取得wifi模块的控制，所以像Day 1当中那样用有线方式连接也完全没问题，连上之后再去查找问题所在吧。
4. 启动mjpg-streamer服务。用` vim /etc/config/mjpg-streamer`修改mjpg-streamer配置文件，找到里面的enabled设置，将0改为1即可。然后记得看一下这个配置文件里面的其他内容，都是很直白的内容，注意fps，led是可以删除的设置内容，目前不需要指定帧率和led灯的只是状态。记住默认的帐号密码和端口之后保存退出。然后启动服务：`/etc/init.d/mjpg-streamer start`，以及确保OpenWRT开机自启动`/etc/init.d/mjpg-streamer enable`。
5. 将准备好的mjpg摄像头插到wifi模块的usb接口上。
5. 电脑上打开浏览器，网址栏输入192.168.1.1:8080。默认mjpg-streamer的服务器是架设在8080端口上的。你就可以看到实时的监控画面咯！恭喜！

---

### 进阶
信息论里有一个基本的常识就是，从单一信源获得信息的时候必将会有信息的丢失，说成白话就是咱们听老师上课绝对不会全部记住老师讲了什么。所以我们每次的进阶内容还是很推荐大家阅读的，从多个途径对同一主题了解，事倍功倍。
第二天的进阶内容是让你熟悉一下[mjpg-streamer在OpenWRT中的使用](https://wiki.openwrt.org/doc/howto/webcam)。请自己发现它里面补充说明的内容哦！因为我也是参照它学习的呢！
学有余力的geek们，可以看一下关于我们wifi模块的一些硬件信息：在[这里](https://squonk42.github.io/TL-WR703N/)，[这里](https://wiki.openwrt.org/toh/tp-link/tl-wr703n)，还有[这里](https://wiki.openwrt.org/toh/hwdata/tp-link/tp-link_tl-wr703n_1)。

