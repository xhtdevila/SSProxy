#!/system/bin/sh
xiao="${0%/*}"
box=${xiao%/*}/bin/busybox
cd $xiao







#↓替换已转换文件中的Host(0=关闭，1=打开)
TF=1
#↓如果Host='',则使用SSR衔接中的混淆参数
Host='ltetp.tv189.com\\r\\nPort'







link_conversion()   {
    label='';ip='';port='';password='';method='';protocol='';obfs='';protocol_param='';host='';remarks='';group=''
    allstr=$(echo -n $1 | $box cut -d'/' -f3 | $box sed s#'-'#'+'#g | $box sed s#'_'#'/'#g | base64 -d 2>&-)
    fstr=$(echo -n $allstr | $box cut -d'/' -f1)
    #获取IP,端口,密码,加密方式,协议,混淆方式,协议参数
    ip=$(echo -n $fstr | $box cut -d':' -f1)
    port=$(echo -n $fstr | $box cut -d':' -f2)
    password=$(echo -n $fstr | $box cut -d':' -f6 | $box sed s#'-'#'+'#g | $box sed s#'_'#'/'#g | base64 -d 2>&-)
    method=$(echo -n $fstr | $box cut -d':' -f4)
    protocol=$(echo -n $fstr | $box cut -d':' -f3)
    obfs=$(echo -n $fstr | $box cut -d':' -f5)
    protocol_param=$(echo -n $protoparam | $box sed s#'-'#'+'#g | $box sed s#'_'#'/'#g | base64 -d 2>&-)
    #获取混淆参数
    eval $(echo -n $allstr | $box cut -d'?' -f2 | $box sed s/'&'/';'/g)
    host=$(echo -n $obfsparam | $box sed s#'-'#'+'#g | $box sed s#'_'#'/'#g | base64 -d 2>&-)
    [ "$Host" != "" ] && host=$Host
    #获取配置名称
    remarks=$(echo -n $remarks | $box sed s#'-'#'+'#g | $box sed s#'_'#'/'#g | base64 -d 2>&-)
    group=$(echo -n $group | $box sed s#'-'#'+'#g | $box sed s#'_'#'/'#g | base64 -d 2>&-)
    [ "$group" = "" ] && label=$remarks || label=$group'-'$remarks
    [ "$label" = "" ] && label='自动转换'
}


get_ip()   {
    isip=$(echo $ip | $box grep '[a-z]')
    if [ "$isip" != "" ];then
        isip=$($box ping -c1 -w1 -W1 $ip | $box grep 'PING' | $box cut -d'(' -f2 |  $box cut -d')' -f1)
        checkip=$(echo "$isip" | $box grep '\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}')
        if [ "$isip" != "" -a "$isip" = "$checkip" ];then
            ip=$isip
        fi
    fi
}


get_ip_address()   {
    if [ "$label" = "自动转换" ];then
        curl -o xhp ip.cn?ip=$ip >/dev/null 2>&1
        address=`$box cat xhp`
        $box rm -rf xhp
        address=${address##*来自：}
        address=${address%%\ *}
        [ "$address" != "" ] && label=$address
    fi
}


change()   {
    if [ "$TF" = "1" -a "$Host" != "" ];then
        for x in $($box ls);do
            h=$(head -1 $x | $box grep '^#转换') >/dev/null 2>&1
            [ "$h" = "" ] && continue
            $box sed -i "s/host='.*'/host='$Host'/g" $x
        done
    fi
}


makeconf()   {
$box cat > $1 << EOF
#转换时间：`$box date +%Y-%m-%d`  |  `$box date +%w`  |  `$box date +%T`

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
    for x in $($box ls);do
        h=$(head -1 $x | $box grep '^ssr://') >/dev/null 2>&1
        [ "$h" = "" ] && continue
        echo "\n\n找到待转换文件$x..."
        link_conversion $h >/dev/null 2>&1
        get_ip
        get_ip_address
        makeconf $x
        h=$(head -1 $x | $box grep '^ssr://') >/dev/null 2>&1
        [ "$h" = "" ] && echo "\n转换文件$x成功...\n\n" || echo "\n转换文件$x失败...\n\n"
    done
}



main
change
$box chmod -R 777 * >/dev/null 2>&1
$box find . -name "*.bak"  | $box xargs $box rm -f


