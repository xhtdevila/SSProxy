#!/system/bin/sh
xiao="${0%/*}"
box=$xiao/bin/busybox
cd $xiao
. ./setting.ini



#↓获取应用UID
getuid() {
    bm=$(echo $1 | $box grep -i '[a-z]')
    if [ "$bm" != "" ];then
        re=$($box grep -m1 -i "$1" /data/system/packages.list | $box cut -d' ' -f2)
    else
        re=$1
    fi
}



#↓删除备份/获取权限
$box find . -name "*.bak"  | $box xargs $box rm -f >/dev/null 2>&1
$box chmod -R 777 * >/dev/null 2>&1
#↓关闭网络
[ "$WLI" = "1" ] && svc data disable >/dev/null 2>&1
#↓关闭核心
allapp='redsocks2 gost pdnsd ss-local'
for x in $allapp;do
    $box pkill $x
done
#↓iptables规则关闭
$box ip rule del fwmark 0x6688 table 121 > /dev/null 2>&1
$box ip route del local 0.0.0.0/0 dev lo table 121 > /dev/null 2>&1
iptables -t nat -F OUTPUT
iptables -t nat -F PREROUTING
iptables -t mangle -P OUTPUT ACCEPT
iptables -t mangle -F OUTPUT
iptables -t mangle -F PREROUTING
#↓检测/停止脚本
if [ "$1" = "stop" ];then
    ./state.sh
    exit 0
fi



#↓获取SSR文件
if [ "$vpsconf" != "" ];then
    for x in $($box ls ./vps) mark;do
        filename=${x%.*}
        if [ "$filename" = "$vpsconf" -o "$x" = "$vpsconf" ];then
             . ./vps/$x
            break
        elif [ "$x" = "mark" ];then
            echo "\n\n\n\n →_→ 未找到 $vpsconf 文件 ←_←"
            exit 0
        fi
    done
fi
#↓建立pdnsd.conf文件
echo "
global {
    perm_cache = 2048;
    cache_dir=\"/dev/null\";
    server_ip = 0.0.0.0;
    server_port = 1053;
    query_method = tcp_only;
    run_ipv4 = on;
    min_ttl = 10800;
    max_ttl = 86400;
    timeout = 20;
    daemon = on;
}
server {
    label = \"ss-local\";
    ip = $dns;
    port = 53;
    reject_policy = negate;
    reject_recursively = on;
    timeout = 5;
}
rr {
    name=localhost;
    reverse=on;
    a=127.0.0.1;
    owner=localhost;
    soa=localhost,root.localhost,42,86400,900,86400,86400;
}" > bin/pdnsd.conf
#↓建立redsocks2.conf文件
echo "
base {
    log_debug = off;
    log_info = off;
    log = stderr;
    daemon = on;
    redirector = iptables;
}
redsocks {
    local_ip = 0.0.0.0;
    local_port = 1080;
    ip = 127.0.0.1;
    port = 1081;
    type = socks5;
}
redudp {
    local_ip = 0.0.0.0;
    local_port = 1088;
    ip = 127.0.0.1;
    port = 1082;
    type = socks5;
    udp_timeout = 20;
}" > bin/redsocks2.conf
#↓建立ss-local.conf文件
echo "
{
    \"server\": \"$ip\",
    \"server_port\": \"$port\",
    \"local_port\": 1081,
    \"password\": \"$password\",
    \"method\":\"$method\",
    \"timeout\": 600,
    \"protocol\": \"$protocol\",
    \"obfs\": \"$obfs\",
    \"obfs_param\": \"$host\",
    \"protocol_param\": \"$protocol_param\"
}" > bin/ss-local.conf
#↓建立gost.conf文件
echo "
{
    \"ServeNodes\": [
        \"socks://127.0.0.1:1082\"
    ],
    \"ChainNodes\": [
        \"socks://127.0.0.1:1081\",
        \"socks://supppig:$gostpwd@$gostip:$udpport\"
    ]
}" > bin/gost.conf
$box chmod -R 777 ./bin/*.conf >/dev/null 2>&1



#↓添加iptables链
iptables -t mangle -I OUTPUT -p udp -j MARK --set-mark 0x6688
iptables -t mangle -I PREROUTING -p udp -j TPROXY --on-port 1088 --tproxy-mark 0x6688
for x in 0/8 127/8 10/8 172.16/12 192.168/16 100.64/10 169.254/16 224/3;do
    iptables -t mangle -I PREROUTING -d $x -j ACCEPT
done
iptables -t nat -I OUTPUT -p udp --dport 53 -j REDIRECT --to 1053
iptables -t nat -I OUTPUT -p tcp -m owner ! --uid-owner 3004 -j REDIRECT --to 1080
iptables -t mangle -I OUTPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t mangle -I OUTPUT ! -p udp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -I PREROUTING -p 17 --dport 53 -j REDIRECT --to-ports 1053
iptables -t nat -I PREROUTING -s 192.168/16 -p 6 -j REDIRECT --to-ports 1080
$box ip rule add fwmark 0x6688 table 121
$box ip route add local 0.0.0.0/0 dev lo table 121
#↓启动核心
$box nohup ./bin/redsocks2 -c ./bin/redsocks2.conf >/dev/null &
$box nohup ./bin/gost -C ./bin/gost.conf >/dev/null &
$box nohup ./bin/pdnsd -c ./bin/pdnsd.conf >/dev/null &
$box nohup ./bin/ss-local -a 3004 -c ./bin/ss-local.conf --acl ./bin/*.acl >/dev/null &
#↓TCP放行
if [ "$TCP_FX" != "" ];then
    for x in $TCP_FX;do
        getuid $x
        if [ "$re" != "" ];then
            iptables -t nat -I OUTPUT -m owner --uid $re -p 6 -j ACCEPT
            iptables -t mangle -I OUTPUT -m owner --uid $re -p 6 -j ACCEPT
        fi
    done
fi
#↓TCP禁网
if [ "$TCP_JW" != "" ];then
    for x in $TCP_JW;do
        getuid $x
        if [ "$re" != "" ];then
            iptables -t mangle -I OUTPUT -m owner --uid-owner $re -j DROP
        fi
    done
fi
#↓UDP放行
if [ "$UDP_FX" != "" ];then
    for x in $UDP_FX;do
        getuid $x
        if [ "$re" != "" ];then
            iptables -t nat -I OUTPUT -m owner --uid $re -p 17 -j ACCEPT
            iptables -t mangle -I OUTPUT -m owner --uid $re -p 17 -j ACCEPT
        fi
    done
fi
#↓网卡放行
if [ "$NC_FX" != "" ];then
    for x in $NC_FX;do
        iptables -t nat -I OUTPUT -o $x -j ACCEPT
        iptables -t mangle -I OUTPUT -o $x -j ACCEPT
    done
fi
#↓WIFI代理
if [ "$WIF" != "1" ];then
    iptables -t nat -I OUTPUT -o wlan+ -j ACCEPT
    iptables -t mangle -I OUTPUT -o wlan+ -j ACCEPT
fi



#↓删除生成文件
$box rm ./bin/*.conf >/dev/null 2>&1
#↓开启网络
[ "$WLI" = "1" ] && nohup svc data enable >/dev/null &
#↓检测脚本
./state.sh


