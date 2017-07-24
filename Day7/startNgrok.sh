while [ -z $(iwconfig | grep "Link Quality")  ]; do
	sleep 2
done
ngrokc -SER[Shost:ngrok.inverfengxue.top,Sport:5728] -AddTun[Type:http,Lhost:127.0.0.1,Lport:8080,Sdname:cai] > /dev/null &
