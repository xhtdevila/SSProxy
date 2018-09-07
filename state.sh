#!/system/bin/sh
xiao="${0%/*}"
box=$xiao/bin/busybox
cd $xiao



#↓获取busybox
busybox="find xargs rm chmod pgrep"
for x in $busybox;do
    type $x 2>&- >&-
    if [ "$?" = "0" ];then
        eval b$x=$x
    else
        eval b$x=\"$box $x\"
    fi
done
#↓删除备份/获取权限
${bfind} . -name "*.bak"  | ${bxargs} ${brm} -f >/dev/null 2>&1
${bchmod} -R 777 * >/dev/null 2>&1
#↓检测脚本
echo ""
for x in redsocks2 gost pdnsd ss-local;do
    if [ "`${bpgrep} $x`" != "" ];then
        echo "✔ $x"
    else
        echo "✘ $x"
    fi
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


