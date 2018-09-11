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
#↓显示输出
echo ""
for x in redsocks2 gost pdnsd ss-local;do
    [ "`$box pgrep $x`" != "" ] && A=" ✔" || A=" ✘"
    [ "$x" = "gost" -a "$TX" != "" ] && B="▲$TX"
    [ "$x" = "pdnsd" -a "$RX" != "" ] && B="▼$RX"
    printf "%-5s%-13s%s\n" "$A" "$x" "$B"
    A="";B=""
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


