#!/bin/bash
#Author NuoMark
#Email HunKnight@163.com
#CreateDate 2020-10-10
#Description Create fully automatic operation and maintenance scripts for Linux system goals
#Motto Believe in YouSelf ,Nothing is impossible

#*********************Start Definition Area(定义区)*********************
#运行脚本目录地址
work_path=$(dirname $(readlink -f "JavaEnv.sh"))
#应用安装目录
install_dir=/deploy
#存储包后缀Map
declare -A package_suffix_map
#应用下载跟地址Map
declare -A application_download_root_address_map
#全局缓存Map
declare -A global_cache_map

export TOP_PID=$$
#颜色定义
# 红色字体:表示操作失败、 绿色字体:表示操作成功 、 黄色字体:重要信息提醒 、 蓝色字体:描述信息 粉色字体: 表示选项颜色 紫色字体:应用导航提示
white_font="\033[0m" && red_font="\033[31m" && green_font="\033[32m" && yellow_font="\033[33m" && blue_font="\033[34m" && pink_font="\033[35m" && purple_font="\033[36m"

#*********************End Start Definition Area*********************

#*********************Start Method Area(方法区)*********************
#网络地址检测 返回Http状态码
Address_Detection() {
    HTTP_CODE=$(curl -o /dev/null -s --head -w "%{http_code}" $1)
    return ${HTTP_CODE}
}
#退出脚本命令
Exit_Script(){ 
    kill -s TERM $TOP_PID 
}
#网络地址检测
Network_Detection() { 
    echo  "" 
    #百度检测,检测网络是否可用
    Address_Detection www.baidu.com
    restul_code=$(echo $?)
    if [[ $restul_code == 200 ]]; then
        echo -e "${green_font}当前网络可用,继续执行脚本${white_font}"

    else
        echo -e "${red_font}当前网络异常,请检查网络是否正常${white_font}"
       :|Exit_Script
    fi
}

System_Variable() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        ...
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    global_cache_map["OS"]=${OS}
    global_cache_map["Version"]=${VER}
}

#资源初始化
Resource_Initialization() {
    #包后缀
    package_suffix_map["tar"]=".tar.gz"
    package_suffix_map["tgz"]=".taz"
    package_suffix_map["rpm"]=".rpm"
    package_suffix_map["zip"]=".zip"

    #应用下载根目录地址
    application_download_root_address_map["zookeeper"]="https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/"
    application_download_root_address_map["kafka"]=""
    application_download_root_address_map["nginx"]="http://nginx.org/download/"
    application_download_root_address_map["nexus"]=""
    application_download_root_address_map["redis"]="http://download.redis.io/releases/"

}

#创建根目录
Create_Installation_Directory() {
    echo ""
    if [ ! -d "${install_dir}" ]; then
        mkdir ${install_dir}
        echo -e "${green_font}创建安装根目录${white_font}"
        echo -e "☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆"
    else
        echo -e "☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆"
    fi
    echo -e "${yellow_font}安装根目录: ${install_dir} ${white_font}"
    echo -e "☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆"
}
#检查环境
CheckEnvironment() {
    echo ""
    echo -e "${purple_font}开始检查环境${white_font}"
    if [ $(command -v lynx) ]; then
        echo -e "${green_font}lynx环境已安装${white_font}"
    else
        echo -e "${purple_font}开始安装lynx环境${white_font}"
        dnf config-manager --set-enabled PowerTools
        yum install -y lynx
    fi

    for i in nss gcc gcc-c++ make openssl-devel pcre-devel epel-release zlib zlib-devel yum-utils device-mapper-persistent-data lvm2 jemalloc-devel; do
        rpm -q $i
        if [ $? -ne 0 ]; then
            echo -e "${purple_font} 正在安装 $i 环境 ${white_font} \n"
            yum install -y $i
            #yum install -y $i &>/dev/null
        fi
    done

}
#密码生成
Password_Generation() {
    s=('<' '>' '+' '.' '&' ';' ':' '{' '}' a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9)
    s_length=${#s[*]}
    i=0
    length=12
    while [ $i -lt $length ]; do
        #$RANDOM生成0-32767之间的整数随机数，
        srand[$i]=${s[$((RANDOM % s_length))]}
        let i++
    done
    echo ${srand[*]} | sed 's/ //g'
}

#解析下载地址应用版本地址
#Centos8 需要环境检测
#    dnf config-manager --set-enabled PowerTools
#    yum install lynx
#第一个参数 http root地址 只提供二层地址解析
#第二个参数一层解析关键字
#第三个参数 安装包拓展名
Resolve_Address() {
    echo ""
    #自增值属性
    increase=0
    lynx -dump $1 >tmp_download_link.txt
    cat tmp_download_link.txt | grep $2 | cut -d\" -f 2 >tmp_root.txt

    ##TODO优化点 现今是输入完整的url地址进行解析 优化方向通过输入序列号进行选择
    tail -n 100 tmp_root.txt | while read line; do
        increase=$(($increase + 1))
        echo -e ${increase}". "${pink_font}${line#*.}${white_font}
    done
    #TODO 假如别人输入的不是展示的url地址 会后续逻辑走不通
    echo -n -e "请复制完整URL地址填写:" # 参数-n的作用是不换行，echo默认换行
    read link_root             # 把键盘输入放入变量link_root

    echo -e "\n${blue_font}提示:如果解析出来的地址是根目录地址,那么需要进行二次解析,如果是具体文件地址无需二次解析${white_font}\n"

    read -e -p "是否对URL地址进行二次解析？[y/n](默认Y):" choose_y
    if [[ ${choose_y} == [Yy] ]] || [[ ${choose_y} == "" ]]; then
        echo ""
        lynx -dump ${link_root} >tmp_link_file.txt
        cat tmp_link_file.txt | grep 'http' | grep $3 | cut -d\" -f 2 >tmp_result.txt

        cat tmp_result.txt | while read line; do
            increase=$(($increase + 1))
            echo -e ${increase}". "${pink_font}${line#*.}${white_font}
        done
        echo -n -e "请复制完整URL地址填写:" # 参数-n的作用是不换行，echo默认换行
        read install_link
        global_cache_map["link"]=${install_link}
    else
        global_cache_map["link"]=${link_root}

    fi

    Clean_files ${work_path} "tmp_"

}
#清理相关目录与关键字相匹配的文件及文件夹
#第一个参数文件夹目录
#清理关键字
Clean_files() {
    files=$(ls $1)
    for filename in $files; do
        result=$(echo ${filename} | grep "$2")
        if [[ ${result} != "" ]]; then
            rm -rf $1/$filename
        fi
    done
}

#下载文件
#第一个参数 清理关键字
#第二个参数 完整的URL地址
#第三个参数 完整的文件名称
Download_File() {
    echo ""
    #清理安装目录与关键字相匹配的文件及文件夹
    Clean_files ${install_dir} $1
    #判断脚本工作目录文件是否存在
    if [ ! -f "${work_path}/$3" ]; then
        wget $2
    fi

    #解压方式
    case "$3" in
    *.tar.gz)
        #-v 详细显示正在处理的文件名
        tar -zxf ${work_path}/$3 -C $install_dir
        ;;
    *.zip)
        unzip ${work_path}/$3 -d $install_dir
        ;;
    *.tgz)
        tar -zxf ${work_path}/$3 -C $install_dir
        ;;
    *.rpm) ;;
    esac

    #清理工作目录与关键字相匹配的文件及文件夹
    read -e -p "是否清理${work_path}目录中 $1 相关文件？[y/n](默认Y):" choose_y
    if [[ ${choose_y} == [Yy] ]] || [[ ${choose_y} == "" ]]; then
        Clean_files ${work_path} $1
        echo -e "${green_font}${work_path}目录中的${yellow_font}$1${white_font}${white_font}相关文件已删除"
    else
        echo -e "${yellow_font}删除操作已取消.${white_font}"

    fi
    echo ""
}

#应用安装前检查服务是否在运行
Before_Service_Status() {
    echo ""
    #TODO可能有多个进程ID
    PID=$(ps -ef | grep "$1" | grep -v grep | awk '{ print $2 }')

    if [ ! -z "$PID" ]; then
        echo -e "${green_font}$1服务正在运行。正在执行关闭$1服务。${white_font} "
        kill -9 "$PID"
    else
        echo -e "${red_font} $1服务未运行。${white_font} "
    fi
}
#应用安装后检查服务是否在运行
After_Service_Status() {
    if test $(pgrep -f $1 | wc -l) -eq 0; then
        echo -e "${red_font}$1启动失败。${white_font} \n"
    else
        echo -e "${green_font}$1启动成功!${white_font} \n"
        :|Exit_Script
    fi
}
#服务检查
#第一个参数 服务名称
service_check() {
    echo -e "${green_font}服务自检程序会执行3次，每次相隔5S ${white_font}"
    #解决延迟启动的问题  自检程序 自检三次 每次相隔5S
    for i in 1 2 3; do
        echo -e "\n${yellow_font}第 $i 次自检${white_font}\n"
        After_Service_Status ${keyword}
        sleep 5s
    done
}
#Zookeeper安装
Zookeeper_Installation() {
    echo ""
    echo -e "${purple_font}开始安装Zookeeper应用${white_font}"

    #TODO优化点,通用参数是否可以集中管理

    #需要的变量数据
    suffix=${package_suffix_map["tar"]}
    root_link=${application_download_root_address_map["zookeeper"]}

    #连接网络进行选择下载
    Resolve_Address ${root_link} '/zookeeper-' ${suffix}
    #完整的地址
    complete_address=${global_cache_map["link"]}

    #安装包文件全名（带后缀）
    file_name=${complete_address##*/}
    #文件夹名称
    folder_name=${file_name//${suffix}/}
    #app安装目录
    app_install_dir=${install_dir}/${folder_name}

    keyword="zookeeper"

    Before_Service_Status ${keyword}

    #处理工作目录安装包
    Download_File ${keyword} ${complete_address} ${file_name}

    cd ${app_install_dir}
    cp conf/zoo_sample.cfg conf/zoo.cfg

    sed -i '/zookeeper-config-start/,+3d' ~/.bash_profile
    echo "#zookeeper-config-start" >>~/.bash_profile
    echo "export ZOOKEEPER_INSTALL=${app_install_dir}" >>~/.bash_profile
    echo "export PATH=\$PATH:\$ZOOKEEPER_INSTALL/bin" >>~/.bash_profile
    echo "#zookeeper-config-end" >>~/.bash_profile 

    #TODO 优化点 是否优化Ip的获取策略 或者系统变量集中管理
    ip="$(hostname --fqdn)"
    echo 'server.1='$ip':2888:3888' >>conf/zoo.cfg

    #修改原始路径
    sed -i 's#/tmp/zookeeper#'${app_install_dir}'/data/data#' conf/zoo.cfg

    #添加log日志
    sed -i '/^dataDir/a\dataLogDir='${app_install_dir}'/data\/logs' conf/zoo.cfg

    ./bin/zkServer.sh start

    echo -e "${purple_font}开始对Zookeeper服务进行自检${white_font} \n"
    service_check ${keyword}
}
#Nginx安装 
Nginx_Installation() { 
    if [ ${global_cache_map["Version"]} -ne 7 ]; then
        echo -e "\n${yellow_font}Nginx安装包方式仅支持Linux7版本${white_font}\n"
        :|Exit_Script
    fi
    echo ""
    echo -e "${purple_font}开始安装Nginx应用${white_font}"
    #需要的变量数据
    suffix=${package_suffix_map["tar"]}
    root_link=${application_download_root_address_map["nginx"]}

    #连接网络进行选择下载
    Resolve_Address ${root_link} '/nginx-' ${suffix}
    #完整的地址
    complete_address=${global_cache_map["link"]}

    #安装包文件全名（带后缀）
    file_name=${complete_address##*/}
    #文件夹名称
    folder_name=${file_name//${suffix}/}

    #app安装目录
    app_install_dir=${install_dir}/${folder_name}

    keyword="nginx"

    killall ${nginx}

    #处理工作目录安装包
    Download_File ${keyword} ${complete_address} ${file_name}

    cd $app_install_dir
    ./configure --prefix=${app_install_dir} --with-http_stub_status_module --with-http_random_index_module --with-http_ssl_module
    make test
    make install
    mkdir logs
    ./sbin/nginx
    echo -e "${purple_font}开始对Nginx服务进行自检${white_font} \n"
    service_check ${keyword}
}
#Redis安装
Redis_Installation() {
    echo ""
    echo -e "${purple_font}开始安装Redis应用${white_font}"
    #需要的变量数据
    suffix=${package_suffix_map["tar"]}
    root_link=${application_download_root_address_map["redis"]}

    #连接网络进行选择下载
    Resolve_Address ${root_link} '/redis-' ${suffix}
    #完整的地址
    complete_address=${global_cache_map["link"]}

    #安装包文件全名（带后缀）
    file_name=${complete_address##*/}
    #文件夹名称
    folder_name=${file_name//${suffix}/}

    #app安装目录
    app_install_dir=${install_dir}/${folder_name}

    keyword="redis"

    Before_Service_Status ${keyword}

    #处理工作目录安装包
    Download_File ${keyword} ${complete_address} ${file_name}

    cd $app_install_dir

    make test
    make install

    ./src/redis-server &

    echo -e "${purple_font}开始对Redis服务进行自检${white_font} \n"
    service_check ${keyword}
}

#Docker
Docker_Installation() {
    echo -e "${purple_font}开始安装Docker${white_font} \n"
    docker_version="$(docker -v | cut -d ' ' -f3 | cut -d ',' -f1)"
    #当串的长度为0时为真(空串)
    if [ -z "$docker_version" ]; then
        sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        if [[ ${global_cache_map["Version"]} == "8" ]]; then
            yum makecache
            yum install https://download.docker.com/linux/fedora/30/x86_64/stable/Packages/containerd.io-1.2.6-3.3.fc30.x86_64.rpm
            sudo yum -y install docker-ce --allowerasing
        else
            sudo yum makecache fast
            sudo yum -y install docker-ce
        fi
        Before_Service_Status "yum"
        sudo systemctl start docker
    fi
    # -n 当串的长度大于0时为真(串非空)
    if [ -n "$docker_version" ]; then
        echo -e "${green_font} docker 已经安装 ${white_font} \n"
    fi
    docker --version
}
#nexus
Nexus_Installation() {
    echo ""
    echo -e "${purple_font}开始安装Nexus应用${white_font}"
    #需要的变量数据
    suffix=${package_suffix_map["tar"]}
    root_link=${application_download_root_address_map["redis"]}

    #连接网络进行选择下载
    Resolve_Address ${root_link} '/redis-' ${suffix}
    #完整的地址
    complete_address=${global_cache_map["link"]}

    #安装包文件全名（带后缀）
    file_name=${complete_address##*/}
    #文件夹名称
    folder_name=${file_name//${suffix}/}

    #app安装目录
    app_install_dir=${install_dir}/${folder_name}

    keyword="redis"

    Before_Service_Status ${keyword}

    #处理工作目录安装包
    Download_File ${keyword} ${complete_address} ${file_name}

    cd $app_install_dir
}

#从for循环中返回字符串处理
Return_For_Str(){ 
    if [[ $1 == "openJdk" ]]; then 
        files=$(ls "${app_install_dir}")
        for filename in $files; do
            result=$(echo ${filename} | grep ${install_version}"-") 
            if [[ ${result} != "" ]]; then 
               echo "${result}"
            fi

        done
    fi
}
#OpenJDk
OpenJdk_Installation() {
    
    keyword="openJdk"
    #检查OpenJdk是否安装
    yum list installed | grep -e java -e jdk
    if [ $? -eq 0 ]; then
        read -p "继续执行将卸载JDK,y确定，其他退出?" choose
        if [ ${choose} == "y" ] || [ ${choose} == "" ]; then
            yum -y remove java-* &>/dev/null
            yum -y remove tzdata-java* &>/dev/null
        else
           :|Exit_Script
        fi
    fi
    echo -e "\n${purple_font}开始安装OpenJDK应用${white_font}"
    echo -e " 
${blue_font}———————————————————————————请选择OpenJdk版本—————————————————————————————————${white_font}
${pink_font}1. java-1.8.0-openjdk.x86_64${white_font} 
${pink_font}2. java-11-openjdk.x86_64${white_font}  
"
    echo && read -e -p "请输入数字 ：" num
    case "$num" in
    1)
        install_version="java-1.8.0-openjdk"
        ;;
    2)
        install_version="java-11-openjdk"
        ;;
    *)
        echo -e "${yellow_font}请输入正确的数字${white_font}"
        ;;
    esac

    yum install -y ${install_version} ${install_version}-devel

    #解放如何从循环中返回字符串
    result=$(Return_For_Str  ${keyword} ${app_install_dir}) 

    app_install_dir="/usr/lib/jvm"/${result}

    sed -i '/OpenJdk-config-start/,+4d' ~/.bash_profile
    echo "#OpenJdk-config-start" >>~/.bash_profile
    echo "export JAVA_HOME=${app_install_dir}" >>~/.bash_profile
    echo "export CLASSPATH=.:\$JAVA_HOME/jre/lib/rt.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >>~/.bash_profile
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >>~/.bash_profile
    echo "#OpenJdk-config-start" >>~/.bash_profile 
}
#*********************Start Local StandAlone Installation(本地安装)*********************
Local_StandAlone_Installation() {
    echo -e " 
${blue_font}———————————————————————————安装包方式—————————————————————————————————${white_font}
${pink_font}1. OpenJdk${white_font} 
${pink_font}2. Nginx${white_font} 
${pink_font}3. Docker${white_font} 
${pink_font}4. Redis${white_font} 
${pink_font}5. Zookeeper${white_font} 
${pink_font}6. Kafka${white_font}    
${blue_font}———————————————————————————Docker方式—————————————————————————————————${white_font}
${pink_font}7. Nexus${white_font}
${pink_font}8. Mysql${white_font} 
${pink_font}9. Nacos${white_font}
${pink_font}10. Sentinel${white_font}
"
    echo && read -e -p "请输入数字 ：" num
    case "$num" in
    1)
        OpenJdk_Installation
        ;;
    2)
        Nginx_Installation
        ;;
    3)
        Docker_Installation
        ;;
    4)
        Redis_Installation
        ;;
    5)
        Zookeeper_Installation
        ;;
    6)
        Kafka_Installation
        ;;
    7)
        Nexus_Installation
        ;;
    8)
        Docker_Installation
        ;;
    9)
        Docker_Installation
        ;;
    10)
        Docker_Installation
        ;;
    *)
        echo -e "${yellow_font}请输入正确的数字${white_font}"
        ;;
    esac
}
#*********************End Local Installation*********************

#*********************Start Cluster Installation(集群安装)*********************
Cluster_Installation() {
    echo -e "${yellow_font}Docker方式安装应用不支持集群安装${white_font}"
    echo -e "${yellow_font}后续计划进行开发${white_font}"
}
#*********************End Cluster Installation*********************

#*********************End Method Area*********************

#*********************Start Entrance(入口)*********************
Network_Detection
Create_Installation_Directory
Resource_Initialization
CheckEnvironment
System_Variable
echo -e "${blue_font}
---------------- Linux环境运维脚本 NuoMark 制作 -----------------
------ JAVA Development Environment Installation Script ------
---- Github:https://github.com/PerseSniper/ShellTools.git ----\n
———————————————————————————安装方式————————————————————————————${white_font}

${pink_font}1. 本地单机安装${white_font} 

${pink_font}2. 集群安装${white_font}
"
echo && read -e -p "请输入数字 ：" num
case "$num" in
1)
    Local_StandAlone_Installation
    ;;
2)
    Cluster_Installation
    ;;
*)
    echo -e "${yellow_font}请输入正确的数字${white_font}"
    ;;
esac
#*********************End Entrance(入口)*********************
