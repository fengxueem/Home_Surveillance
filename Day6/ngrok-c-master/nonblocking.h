#ifndef NONBLOCKING_H_INCLUDED
#define NONBLOCKING_H_INCLUDED
#include "config.h"

#include <string.h>
#if  WIN32
#include <winsock.h>
#include <winsock2.h>
#include <windows.h>

#else
#include <fcntl.h>
#include <netinet/in.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#endif
#include <list>

#include "sslbio.h"
using namespace std;

#if WIN32

struct tcp_keepalive {
  u_long onoff;
  u_long keepalivetime;
  u_long keepaliveinterval;
};

#define SIO_RCVALL _WSAIOW(IOC_VENDOR,1)
#define SIO_RCVALL_MCAST _WSAIOW(IOC_VENDOR,2)
#define SIO_RCVALL_IGMPMCAST _WSAIOW(IOC_VENDOR,3)
#define SIO_KEEPALIVE_VALS _WSAIOW(IOC_VENDOR,4)
#define SIO_ABSORB_RTRALERT _WSAIOW(IOC_VENDOR,5)
#define SIO_UCAST_IF _WSAIOW(IOC_VENDOR,6)
#define SIO_LIMIT_BROADCASTS _WSAIOW(IOC_VENDOR,7)
#define SIO_INDEX_BIND _WSAIOW(IOC_VENDOR,8)
#define SIO_INDEX_MCASTIF _WSAIOW(IOC_VENDOR,9)
#define SIO_INDEX_ADD_MCAST _WSAIOW(IOC_VENDOR,10)
#define SIO_INDEX_DEL_MCAST _WSAIOW(IOC_VENDOR,11)

#define RCVALL_OFF 0
#define RCVALL_ON 1
#define RCVALL_SOCKETLEVELONLY 2

inline int SetKeepAlive(int sock){
    BOOL bKeepAlive = TRUE;
    int nRet =setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, (char*)&bKeepAlive, sizeof(bKeepAlive));
    if (nRet == SOCKET_ERROR)
    {
    return -1;
    }

    // ����KeepAlive����
    tcp_keepalive alive_in = {0};
    tcp_keepalive alive_out = {0};
    alive_in.keepalivetime =60000; // ��ʼ�״�KeepAlive̽��ǰ��TCP�ձ�ʱ��
    alive_in.keepaliveinterval =60000; // ����KeepAlive̽����ʱ����
    alive_in.onoff = TRUE;
    unsigned long ulBytesReturn =0;
    //nRet = WSAIoctl(sock, SIO_KEEPALIVE_VALS, &alive_in, sizeof(alive_in),&alive_out, sizeof(alive_out), &ulBytesReturn, NULL, NULL);
    if (nRet == SOCKET_ERROR)
    {
    return -1;
    }
    return 0;
}
#else
#include <netinet/in.h>
#include <netinet/tcp.h>
inline int SetKeepAlive(int sock){
    /*����˵���뵥λ��������˵�Ǻ��뵥λ*/
int keepalive = 1; // ����keepalive����
int keepidle = 60000; // ���������60����û���κ���������,�����̽��
int keepinterval = 60000; // ̽��ʱ������ʱ����Ϊ5 ��
int keepcount = 1; // ̽�Ⳣ�ԵĴ���.�����1��̽������յ���Ӧ��,���2�εĲ��ٷ�.
setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, (void *)&keepalive , sizeof(keepalive ));
setsockopt(sock, SOL_TCP, TCP_KEEPIDLE, (void*)&keepidle , sizeof(keepidle ));
setsockopt(sock, SOL_TCP, TCP_KEEPINTVL, (void *)&keepinterval , sizeof(keepinterval ));
setsockopt(sock, SOL_TCP, TCP_KEEPCNT, (void *)&keepcount , sizeof(keepcount ));
return 0;
}
#endif // WIN32



#if OPENSSL
struct sockinfo
{
    openssl_info *sslinfo;
    int isconnect;
    int istype; //1=remote 2=local,3=cmd
    int tosock;
    unsigned char *packbuf;
    unsigned long long packbuflen;
    int isconnectlocal;
    int linktime;
    int isauth;
};
#else
struct sockinfo
{
    ssl_info *sslinfo;
    int isconnect;
    int istype; //1=remote 2=local,3=cmd
    int tosock;
    unsigned char *packbuf;
    unsigned long long packbuflen;
    int isconnectlocal;
    int linktime;
    int isauth;
};
#endif

inline int setnonblocking(int sServer,int _nMode)
{
    #if WIN32
    DWORD nMode = _nMode;
    return ioctlsocket( sServer, FIONBIO,&nMode);
    #else
    if(_nMode==1)
    {
       return fcntl(sServer,F_SETFL,O_NONBLOCK);
    }
    else
    {
      return fcntl(sServer,F_SETFL, _nMode);
    }
    #endif
}
inline int net_dns( struct sockaddr_in *server_addr, const char *host, int port )
{
    struct hostent *server_host;
    if((server_host = gethostbyname(host)) == NULL )
    {
        return -1;
    }
    memcpy((void*)&server_addr->sin_addr,(void*)server_host->h_addr,server_host->h_length);
    server_addr->sin_family = AF_INET;
    server_addr->sin_port   = htons( port );
    return 0;
}

inline int check_sock(int sock)
{
    int error=-1;
    #if WIN32
    int len ;
    #else
    socklen_t len;
    #endif
    len = sizeof(error);
    getsockopt(sock, SOL_SOCKET, SO_ERROR, (char*)&error, &len);
    return error;
}

void clearsock(int sock,sockinfo * sock_info);

inline int SetBufSize(int sock)
{
    //���ջ�����
    int opt=25*1024;//30K
    setsockopt(sock, SOL_SOCKET, SO_RCVBUF, (const char*)&opt,sizeof(opt));
    //���ͻ�����  (���ǧ��Ҫ�������Ͳ���Ҫ������)
   // setsockopt(sock, SOL_SOCKET, SO_SNDBUF, (const char*)&opt,sizeof(opt));
    return 0;
}

#endif // NONBLOCKING_H_INCLUDED
