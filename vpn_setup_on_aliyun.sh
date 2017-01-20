#!/bin/bash

usage()
{
    echo "usage: `basename $0` VPN_CONFIG_NAME ACTION"
}

if [ $# -ne 2 ]
then
    usage
    exit 1
fi

VPN_CONFIG_NAME=$1
ACTION=$2

pppd_stop(){
    echo "[pppd]:stop"
    sudo killall pppd &>/dev/null
    sudo killall pppd &>/dev/null
}

pppd_start(){
    echo "[pppd]:start"
    pppd_stop
    sudo pppd call $1
}

pppd_check(){
    is_running=`ifconfig | grep ppp0`
    if [ "$is_running" == "" ];then
        echo "[pppd]: not running..."
        return 1
    else
        echo "[pppd]: already running..."
        return 0
    fi
}

pppd_check_and_start(){
    pppd_check
    ret=$?
    if [ "$ret" == 1 ];then
        pppd_start $VPN_CONFIG_NAME
    fi
}

WHO_COUNT=`who | awk '{print $6}' | sed 's/(//' | sed 's/)//' | uniq | wc -l`
WHO_IP=`who | awk '{print $6}' | sed 's/(//' | sed 's/)//' | uniq`

route_keep_who(){
    ALIYUN_GATEWAY_IP=`route | grep default | awk '{print $2}'`
    # TODO
    echo "[route_keep_who] who_ip: $WHO_IP"
    echo "[route_keep_who] aliyun_gateway_ip: $ALIYUN_GATEWAY_IP"
    sudo route add -host $WHO_IP gw $ALIYUN_GATEWAY_IP
}

route_del_default(){
    ALIYUN_GATEWAY_IP=`route | grep default | awk '{print $2}'`
    echo "[route_del_default] aliyun_gateway_ip: $ALIYUN_GATEWAY_IP"
    sudo route del -net 0.0.0.0 gw $ALIYUN_GATEWAY_IP
}

route_to_vpn_server(){
    VPN_SERVER_REMOTE_IP=`ifconfig ppp0 2>/dev/null | grep 'inet addr:' | awk '{print $3}' | cut -d: -f2`
    echo "[route_to_vpn_server] vpn_server_remote_ip: $VPN_SERVER_REMOTE_IP"
    sudo route add default gw $VPN_SERVER_REMOTE_IP
}

route_restore_default(){
    echo "who_ip: $WHO_IP"
    ALIYUN_GATEWAY_IP=`route | grep $WHO_IP | awk '{print $2}'`
    echo "[route_restore_default] aliyun_gateway_ip: $ALIYUN_GATEWAY_IP"
    # TODO
    VPN_REMOTE_IP=`ifconfig ppp0 2>/dev/null | grep 'inet addr:' | awk '{print $3}' | cut -d: -f2`
    # TODO
    echo "[route_restore_default] vpn_remote_ip: $VPN_REMOTE_IP"
    sudo route del default gw $VPN_REMOTE_IP
    sudo route add default gw $ALIYUN_GATEWAY_IP
}

# TODO: support multi user choosen
who_check_and_keep(){
    if [ $WHO_COUNT != 1 ];then
        echo "[ERROR]: you are not the only user who logged in"
        exit 1
    fi
    route_keep_who
    
}

case $VPN_CONFIG_NAME in 
    hk1)
        echo "[Config]: hk1" ;;
    hk2)
        echo "[Config]: hk2" ;;
    hk3)
        echo "[Config]: hk3" ;;
    *)
        echo "[ERROR]: invalid vpn config name" ;
        exit 1 ;;
esac

case $ACTION in
    start)
        echo "[action]: start" ;
        who_check_and_keep ;
        pppd_check_and_start ;
        sleep 10 ;
        route_del_default ;
        sleep 1 ;
        route_to_vpn_server ;
        sleep 1 ;
        curl ip.gs ;
        echo "Done." ;;
    stop)
        echo "[action]: stop" ;
        route_restore_default ;
        sleep 1 ;
        pppd_stop ;
        sleep 1 ;
        curl ip.gs ;
        echo "Done." ;;
    *)
        echo "[ERROR]: invalid action" ;
        exit 1 ;;
esac


