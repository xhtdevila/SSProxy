#!/system/bin/sh







#↓替换已转换文件中的Host(0=关闭，1=打开)
TF=1
#↓如果Host='',则使用SSR衔接中的混淆参数
Host='ltetp.tv189.com\\r\\nPort'







busybox()   {
    for u in cut sed base64 grep ping wget cat date ls chmod find xargs rm;do
        type $u 2>&- >&-
        if [ "$?" = "0" ];then
            eval b$u=$u
        else
            eval b$u=\"$busybox $u\"
        fi
    done
}


link_conversion()   {
    label='';ip='';port='';password='';method='';protocol='';obfs='';protocol_param='';host='';remarks='';group=''
    allstr=$(echo -n $1 | ${bcut} -d'/' -f3 | ${bsed} s#'-'#'+'#g | ${bsed} s#'_'#'/'#g | ${bbase64} -d 2>&-)
    fstr=$(echo -n $allstr | ${bcut} -d'/' -f1)
    #获取IP,端口,密码,加密方式,协议,混淆方式,协议参数
    ip=$(echo -n $fstr | ${bcut} -d':' -f1)
    port=$(echo -n $fstr | ${bcut} -d':' -f2)
    password=$(echo -n $fstr | ${bcut} -d':' -f6 | ${bsed} s#'-'#'+'#g | ${bsed} s#'_'#'/'#g | ${bbase64} -d 2>&-)
    method=$(echo -n $fstr | ${bcut} -d':' -f4)
    protocol=$(echo -n $fstr | ${bcut} -d':' -f3)
    obfs=$(echo -n $fstr | ${bcut} -d':' -f5)
    protocol_param=$(echo -n $protoparam | ${bsed} s#'-'#'+'#g | ${bsed} s#'_'#'/'#g | ${bbase64} -d 2>&-)
    #获取混淆参数
    eval $(echo -n $allstr | ${bcut} -d'?' -f2 | ${bsed} s/'&'/';'/g)
    host=$(echo -n $obfsparam | ${bsed} s#'-'#'+'#g | ${bsed} s#'_'#'/'#g | ${bbase64} -d 2>&-)
    [ "$Host" != "" ] && host=$Host
    #获取配置名称
    remarks=$(echo -n $remarks | ${bsed} s#'-'#'+'#g | ${bsed} s#'_'#'/'#g | ${bbase64} -d 2>&-)
    group=$(echo -n $group | ${bsed} s#'-'#'+'#g | ${bsed} s#'_'#'/'#g | ${bbase64} -d 2>&-)
    [ "$group" = "" ] && label=$remarks || label=$group'-'$remarks
    [ "$label" = "" ] && label='自动转换'
}


getvpsip_ping_wget()   {
    isip=$(echo $ip | ${bgrep} '[a-z]')
    if [ "$isip" != "" ];then
        isip=$(${bping} -c1 -w1 -W1 $ip | ${bgrep} 'PING' | ${bcut} -d'(' -f2 |  ${bcut} -d')' -f1)
        checkip=$(echo "$isip" | ${bgrep} '\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}')
        if [ "$isip" != "" -a "$isip" = "$checkip" ];then
            ip=$isip
        else
            ip=$(${bwget} -q -T2 -O- http://119.29.29.29/d?dn=$ip | ${bcut} -d';' -f1)
        fi
    fi
}


makeconf()   {
${bcat} > $1 << EOF
#转换时间：`${bdate} +%Y-%m-%d`  |  `${bdate} +%w`  |  `${bdate} +%T`

#配置名称
label='$label'
#SSR服务器IP
ip='$ip'
#SSR服务器端口
port='$port'
#SSR服务器密码
password='$password'
#SSR加密方式
method='$method'
#SSR协议
protocol='$protocol'
#SSR协议参数
protocol_param='$protocol_param'
#SSR混淆方式
obfs='$obfs'
#SSR混淆参数
host='$host'

#GOST服务器IP
gostip='$ip'
#GOST服务器密码
gostpwd='$password'
#GOST服务器端口
udpport='6688'

#$h
EOF
}


main()   {
    for x in $(${bls});do
        h=$(head -1 $x | ${bgrep} '^ssr://')
        [ "$h" = "" ] && continue
        echo "\n\n找到待转换文件$x..."
        ff="y"
        link_conversion $h >/dev/null 2>&1
        getvpsip_ping_wget
        makeconf $x
        h=$(head -1 $x | ${bgrep} '^ssr://')
        [ "$h" = "" ] && echo "\n转换文件$x成功...\n\n" || echo "\n转换文件$x失败...\n\n"
    done
}


change()   {
    if [ "$TF" = "1" -a "$Host" != "" ];then
        for x in $(${bls});do
            h=$(head -1 $x | ${bgrep} '^#转换')
            [ "$h" = "" ] && continue
            sed -i "s/host='.*'/host='$Host'/g" $x
        done
    fi
}




xiao=$(dirname $0)
busybox=${xiao%/*}/bin/busybox
cd $xiao
busybox
main
change
${bchmod} -R 777 * >/dev/null 2>&1
${bfind} . -name "*.bak"  | ${bxargs} ${brm} -f



