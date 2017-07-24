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