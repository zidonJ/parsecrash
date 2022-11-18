#!/bin/sh

#我们可以在执行 Shell 脚本时，向脚本传递参数，脚本内获取参数的格式为：$n。
#n 代表一个数字，1 为执行脚本的第一个参数，2 为执行脚本的第二个参数，以此类推……

# cd /Applications/Xcode.app/Contents/SharedFrameworks/CoreSymbolicationDT.framework/Versions/A/Resources
# python3 CrashSymbolicator.py -d /Users/jiangzedong/Desktop/w_crash/Weibo.app.dSYM  -o /Users/jiangzedong/Desktop/w_crash/log.crash  -p /Users/jiangzedong/Desktop/w_crash/weibo.ips


green() {
  echo -e "\033[32;40m $1 \033[0m"
}
red() {
  echo -e "\033[31;40m $1 \033[0m"
}
yellow() {
  echo -e "\033[33;40m $1 \033[0m"
}

sys_parse_path=/Applications/Xcode.app/Contents/SharedFrameworks/CoreSymbolicationDT.framework/Versions/A/Resources
dSYM_path=~/Desktop/w_crash/Weibo.app.dSYM
out_path=~/Desktop/w_crash/log.crash
ips_path=~/Desktop/w_crash/weibo.ips
ipa_num="" #75085
parse_path=""
no_download=0

custom_input_path() {

    echo -e "日志解析输出路径:"
      read parse_path

    if [ ! -z $parse_path ]; then
        out_path=$parse_path
    fi

    echo -e "闪退日志路径:"
      read parse_path

    if [ ! -z $parse_path ]; then
        ips_path=$parse_path
    fi

    echo " 符号表路径:${dSYM_path}\n 输出路径:${out_path}\n ips路径:${ips_path}"
}

while [ -n "$1" ] #-n 检测字符串长度是否为0 不为0 返回true
do
    case "$1" in
        -d) dSYM_path="$2"
            shift ;;
        -o) out_path="$2"
            shift ;;
        -p) ips_path="$2"
            shift ;;
        -n) ipa_num="$2"
            shift ;;
        -c) custom_input_path;;
        -e) no_download=1;;
        -h) echo " -d 符号表路径 \n -o 输出路径 \n -p 闪退日志ips路径 \n -n jkens包号 \n -c 从界面用户输入文件路径";;
         *) echo "-d 符号表路径 -o 输出路径 -p 闪退日志ips路径 -n jkens包号"
            exit 1 ;;  # 发现未知参数，直接退出
    esac
    shift
      #shift命令用于对参数的移动(左移)，通常用于在不知道传入参数个数的情况下依次遍历每个参数然后进行相应处理，
      #比如shift 2表示将左侧两个参数丢弃，原来的$3现在变成$1，原来的$5现在变成$3等等，不带参数的单个shift相当于shift 1。
done


parseCrash() {

    local_file=~/Desktop/w_crash/weibo.xcarchive.gzip
    local_archive=~/Desktop/w_crash/weibo.xcarchive
    local_dsym=~/Desktop/w_crash/Weibo.app.dSYM
    # wget下载
    # wget -P $local_file http://jkhelper.client.weibo.cn/static/ios_packages/package_$ips_path/weibo.xcarchive.gzip
    # curl下载

    if [[ no_download -ne 1 ]]; then # 整型不用===判断

        read -p "请输入包号:" ipa_num # -p 提示文案
        if [[ -z $ipa_num ]]; then
            red "包号不存在"
            exit 0
        fi
        
        echo "开始下载符号表"
        
        download_address=http://jkhelper.client.weibo.cn/static/ios_packages/package_$ipa_num/weibo.xcarchive.gzip
        curl $download_address >> $local_file
        echo "下载完成"
    fi
    

    #gzip file #识别后缀，必须把后缀改为.gz
    # gzip -dv $local_file
    # rm -rf $local_file
    if [ -e "$local_file" ]; then #-e 路径是否存在
        #open $local_file #直接使用系统软件打开
        green "解压缩..."
        tar -zxf $local_file
        if [ -e "$local_file" ]; then
            rm -rf $local_file
        fi
        green "拷贝符号表..."
        mv $local_archive/dSYMs/Weibo.app.dSYM ./
        if [[ -e $local_dsym ]]; then
            dSYM_path=$local_dsym
            green "符号表拷贝完成"
        fi
    fi

    if [ -e "$local_archive" ]; then
       green "开始解析"
       
       read -p "请输入log输入路径:" out_path
       if [[ ! -e $out_path ]]; then
            #如果输出路径不存在
            catalogue=${out_path%/*}
            file=${out_path##*/}
            if [[ ! -e $catalogue ]]; then
                green "创建输出目录:${catalogue}"
                sudo mkdir -p $catalogue
                cd $catalogue
                # sudo touch $file
                # echo >> $file
            fi
       fi
       read -p "请输入ips文件路径:" ips_path
       cd $sys_parse_path
       sudo python3 CrashSymbolicator.py -d $dSYM_path  -o $out_path  -p $ips_path
       exit 0
    fi

}

parseCrash
