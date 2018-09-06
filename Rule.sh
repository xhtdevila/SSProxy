#!/system/bin/sh
cd "${0%/*}"

box=*/busybox

for WK in `$box cat /data/misc/net/rt_tables`;do
    if [[ `$box ip addr | $box grep "/" | $box grep -i $WK` != "" ]];then
        SWK=`$box ifconfig $WK` 2>/dev/null
        SWK=${SWK/ MiB/MiB}
        SWK=${SWK/ MiB/MiB}
        SWK=${SWK/ GiB/GiB}
        SWK=${SWK/ GiB/GiB}
    fi
done
apn=`dumpsys connectivity | $box grep -v "<unknown" | $box grep -v "(none)" | $box grep extra | $box awk '{print $9}' | $box cut -d "," -f 1 | $box grep -v "ims"`
ip=`$box ip addr | $box grep global | $box grep inet | $box grep -v inet6 | $box grep -v 10.0 | $box grep -v 192.168 | $box awk '{print $2}' | $box cut -d "/" -f 1`
down=`echo "${SWK#*RX bytes:}" | sed 's/\([^(]*(\)\([^)]*\)\(.*\)/\2/;s/i.*//g'`
up=`echo "${SWK#*TX bytes:}" | sed 's/\([^(]*(\)\([^)]*\)\(.*\)/\2/;s/i.*//g'`

echo "
接点：$apn
内网：$ip
流量：$down - $up"

echo ""
echo ✺ nat表 OUTPUT链:
iptables -t nat -S OUTPUT 2>/dev/null
echo ""
echo ✺ nat表 PREROUTING链:
iptables -t nat -S PREROUTING 2>/dev/null
echo ""
echo ✺ mangle表 OUTPUT链:
iptables -t mangle -S OUTPUT 2>/dev/null
echo ""
echo ✺ mangle表 PREROUTING链:
iptables -t mangle -S PREROUTING 2>/dev/null