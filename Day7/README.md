# Day 7

---

### 材料
无

---
### 思路：wifi模块中增加简化使用的脚本
1. 在Day4中，我们创建了一个开机自动启动的脚本检测STA模式是否工作正常，如果不正常则替换为AP模式，然后我们连上这个AP去校准STA的设置。同样的，我们希望正常情况下，如果STA工作无误，那么我们要保证ngrokc也同时运行，所以类似的写一个开机自启动的脚本放在我们之前那个reboot_ap_sta_detect.sh脚本后面启动。
2. 另外一个很头疼的事情就是STA的设置，要人工查看每个需要连接的wifi热点是什么ssid，什么加密方式，哪个信道。其实我们用一个叫做iwlist的程序就可以把这些信息全部扫描出来，实现自动提取。具体的请看[这篇帖子](https://forum.openwrt.org/viewtopic.php?id=39485)。griguolcomerranas同学在帖子中写了一个脚本实现了自动提取的功能。感谢大神的无私奉献！

---
### 步骤
1. 确保wifi模块上已经完成了Day4的任务，以及刷上了Day6中最后一个客制化版本的OpenWRT。
2. 本地电脑上创建startNgrok.sh脚本。内容是：
	```
	while [ -z $(iwconfig | grep "Link Quality")  ]; do
	        sleep 2
	done
	ngrokc -SER[Shost:ngrok.你的域名,Sport:Day5中定义的http端口] -AddTun[Type:http,Lhost:127.0.0.1,Lport:8080,Sdname:自定义的次级域名] > /dev/null
	```
	首先通过while循环每隔2秒查询是否wifi模块已经成功进入STA模式。成功进入后再启动ngrokc。
	
3. 本地电脑上创建lianjie.sh脚本。内容是：
	```
	iwlist wlan0 scanning > /tmp/wifiscan
	n_results=$(grep -c "ESSID:" /tmp/wifiscan)
	i=1
	while [ "$i" -le "$n_results" ]; do
		if [ $i -lt 10 ]; then
	            cell=$(echo "Cell 0$i - Address:")
	        else
	            cell=$(echo "Cell $i - Address:")
	    fi
	    j=`expr $i + 1`
	    if [ $j -lt 10 ]; then
	            nextcell=$(echo "Cell 0$j - Address:")
	        else
	            nextcell=$(echo "Cell $j - Address:")
	    fi
		awk -v v1="$cell" -v v2="$nextcell" '$0 ~ v1 {p=1} $0 ~ v2{p=0}p' /tmp/wifiscan > /tmp/onecell
		mac=$(grep "Address:" /tmp/onecell | awk '{print $5}')
		ssid=$(grep "ESSID:" /tmp/onecell | awk '{sub(/^[ \s]+ESSID:/, ""); print}')
		encryption=$(grep "Encryption key:" /tmp/onecell | awk '{sub(/^[ \s]+Encryption key:/, "Encryption:"); print}')
		power=$(grep -o "Quality=[0-9]\{2\}" /tmp/onecell | awk '{sub(/Quality=/, ""); print}')
		power=`expr $power \* 10 / 7`
		power="Signal Strength= $power%"
		echo "$mac $ssid $encryption $power" >> /tmp/ssids
		i=`expr $i + 1`
	done
	rm -f /tmp/onecell
	awk '{printf("%3d : %s\n", NR, $0)}' /tmp/ssids > /tmp/sec_ssids
	echo "Available WIFI:"
	cat /tmp/sec_ssids
	echo "Please select a WIFI by entering its number, enter 0 or ctrl+c to quit"
	read nsel
	if [ $nsel = 0 ]; then
		rm /tmp/wifiscan
		rm /tmp/ssids
		rm /tmp/sec_ssids
		exit
	fi
	wifissid=$(grep " $nsel : " /tmp/sec_ssids | awk '{print $4}' | awk '{gsub(/"/, ""); print}' )
	echo "You have choosen $wifissid"
	if [ $nsel -lt 10 ]; then
	        cell=$(echo "Cell 0$nsel - Address:")
	    else
	        cell=$(echo "Cell $nsel - Address:")
	fi
	j=`expr $nsel + 1`
	if [ $j -lt 10 ]; then
	        nextcell=$(echo "Cell 0$j - Address:")
	    else
	        nextcell=$(echo "Cell $j - Address:")
	fi
	awk -v v1="$cell" -v v2="$nextcell" '$0 ~ v1 {p=1} $0 ~ v2{p=0}p' /tmp/wifiscan > /tmp/cellinfo
	wifichannel=$(grep -o "Channel:[0-9]\{2\}" /tmp/cellinfo | awk '{sub(/Channel:/, ""); print}')
	wifimode=$(grep " WEP" /tmp/cellinfo) #check if encryption mode is WEP
	if [ -n "$wifimode" ]; then   #check if $wifimode is not an empty string
	    wifimode="wep"
	else
	    wifimode=$(grep "WPA2 " /tmp/cellinfo) #check if encryption mode is WPA2
	    if [ -n "$wifimode" ]; then
	        wifimode="psk2"
	    else
	        wifimode=$(grep "WPA " /tmp/cellinfo) #check if encryption mode is WPA
	        if [ -n "$wifimode" ]; then
	            wifimode="psk"
	        else
	            wifimode="none"
	        fi
	    fi
	fi
	encryp_on=$(grep " Encryption key:on" /tmp/cellinfo)
	if [ "none" = "$wifimode" ]&&[ -n "$encryp_on" ]; then
	    echo " "
	    echo "Impossible to detect wifi security mode automatically."
	    echo "Please specify the seurity mode of the network."
	    echo " 1: WPA"
	    echo " 2: WPA2"
	    echo " 3: WEP"
	    echo " 4: Undefined"
	    echo -n "Enter the numeric option for your security mode: "
	    read sel_mode
	    case "$sel_mode" in
	        1)
	            wifimode="psk"
	            ;;
	        2)
	            wifimode="psk2"
	            ;;
	        3)
	            wifimode="wep"
	            ;;
	        4)
	            wifimode="none"
	            ;;
	    esac
	fi
	if [ "$wifimode" != "none" ]; then #ask for passwork when needed
	    echo -n "Enter password of the selected WIFI network: "
	    read wifipass
	fi
	rm /tmp/wifiscan
	rm /tmp/cellinfo
	rm /tmp/ssids
	rm /tmp/sec_ssids
	cp /etc/config/wireless.ap+sta /etc/config/wireless
	uci set wireless.radio0.channel=$wifichannel
	uci set wireless.station.mode="sta"
	uci set wireless.station.ssid="$wifissid"
	uci set wireless.station.encryption=$wifimode
	uci set wireless.station.key=$wifipass
	uci commit wireless
	echo -n "
	Trying to connect to WIFI network.
	(Wait a few seconds and check status with: iwconfig )
	"
	wifi down
	wifi
	```
这个脚本可以帮助我们很好的学习awk，grep，uci命令以及一些linux脚本的基础。所以这里不对它做很细的解释，把它的研读作为今天的进阶内容。它的第一步是将iwlist的扫描结果存储，再整理出这次找到的所有ssid的基本信息在屏幕上显示给用户，然后让用户选择一个想要连接的或者直接输入0退出，之后根据用户的选择，将ssid，encryption和channel自动识别，接着让用户输入wifi密码，之后将这些信息全部用uci命令填入wireless，最后重启wifi。有一个细节是当encryption不能自动识别时，它提供了让用户选择具体的加密方式的功能。好啦，就罗嗦到这里，这是一个很好的学习脚本，请认真读吧！

4. 上传脚本到wifi模块。假设我们用的是有线连接将电脑和wifi模块连接起来。用`scp 存放startNgrok.sh的本地目录/startNgrok.sh root@192.168.1.1：/usr/bin/`和`scp 存放lianjie.sh的本地目录/lianjie.sh root@192.168.1.1：/usr/bin/`将它们存入wifi模块的/usr/bin/系统环境目录。

5. 将startNgrok脚本放入开机自启动。类似Day4，开机自启动可以在/etc/rc.local中设置，所以ssh登录wifi模块后，`vim /etc/rc.local`，内容是：
	```
	reboot_ap_sta_detect.sh > /dev/null
	startNgrok.sh > /dev/null
	exit 0
	```
	  
6. 之后如果需要连接新的wifi热点时，请记得用lianjie.sh就可以咯！恭喜！到此为止，项目的框架就结束了。之后可以做的事情有很多哦，比如自己搭建一个网站更加系统的管理这个live video。还可以用OpenVC的库将得到的mjpg视频进行运动检测，人脸检测，识别等等，这些都是在服务器端完成的任务了。

---
### 进阶
研读lianjie.sh。另外将从Day1到Day7的所有内容再整理一遍哦，思路清晰的写下自己的笔记。恭喜！耐心的将这个很可能是自己第一个网络应用搭建完成。

