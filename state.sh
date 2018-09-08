#!/system/bin/sh
xiao="${0%/*}"
box=$xiao/bin/busybox
cd $xiao



#↓删除备份/获取权限
$box find . -name "*.bak"  | $box xargs $box rm -f >/dev/null 2>&1
$box chmod -R 777 * >/dev/null 2>&1
#↓总流量：上传/下载
for x in `$box cat /data/misc/net/rt_tables`;do
    if [[ `$box ip addr | $box grep "/" | $box grep -i $x` != "" ]];then
        SWK=`$box ifconfig $x` 2>/dev/null
    fi
done
TX=`echo "${SWK#*TX bytes:}" | $box sed 's/\([^(]*(\)\([^)]*\)\(.*\)/\2/;s/i.*//g'`
RX=`echo "${SWK#*RX bytes:}" | $box sed 's/\([^(]*(\)\([^)]*\)\(.*\)/\2/;s/i.*//g'`
#↓热点流量：上传/下载
source /data/misc/wifi/hostapd.conf >/dev/null 2>&1
RWK=`$box ifconfig $interface` >/dev/null 2>&1
TX1=`echo ${RWK#*TX bytes} | $box cut -d "(" -f 2 | $box cut -d ")" -f 1 | $box cut -d "i" -f 1`
RX1=`echo ${RWK#*RX bytes} | $box cut -d "(" -f 2 | $box cut -d ")" -f 1 | $box cut -d "i" -f 1`
#↓显示输出
echo ""
for x in redsocks2 gost pdnsd ss-local;do
    [ "`$box pgrep $x`" != "" ] && A=" ✔" || A=" ✘"
    [ "$x" = "gost" -a "$TX" != "" ] && B="▲$TX" 
    [ "$x" = "gost" -a "$RX1" != "0.0 B" ] && C="▲$TX1" 
    [ "$x" = "pdnsd" -a "$RX" != "" ] && B="▼$RX"
    [ "$x" = "pdnsd" -a "$RX1" != "0.0 B" ] && C="▼$RX1"
    printf "%-5s%-13s%-15s%s\n" "$A" "$x" "$B" "$C"
    A="";B="";C=""
done
echo ""
echo "→ nat ←"
iptables -t nat -S OUTPUT
echo ""
iptables -t nat -S PREROUTING
echo ""
echo "→ mangle ←"
iptables -t mangle -S OUTPUT
echo ""
iptables -t mangle -S PREROUTING


