#!/bin/bash

if [ ! -f config.ini ]; then
echo "#[BucketName]
bucketname=
#[Region] 
url=
#[Lock]
lock=0
" > config.ini
fi

source config.ini

function install(){
    echo "检测到你还没有安装OSS管理工具包，键入任意键后开始安装"
    read
    echo "选择你的Linux系统类型" 
select os in Centos7 Ubuntu
do
case $os in "Ubuntu")
echo "开始安装OSS管理工具包,需要超级用户权限"
sudo apt update
sudo apt install -y wget gdebi-core vifm fuse-emulator-gtk
wget http://gosspublic.alicdn.com/ossfs/ossfs_1.80.6_ubuntu18.04_amd64.deb
sudo apt-get install -f -y ./ossfs_1.80.6_ubuntu18.04_amd64.deb
rm ossfs_1.80.6_ubuntu18.04_amd64.deb
return
;;
"Centos7")
echo "开始安装OSS管理工具包,需要超级用户权限"
sudo yum update
sudo yum install -y wget vifm
wget http://gosspublic.alicdn.com/ossfs/ossfs_1.80.6_centos7.0_x86_64.rpm 
sudo yum localinstall -y ossfs_1.80.6_centos7.0_x86_64.rpm
rm ossfs_1.80.6_centos7.0_x86_64.rpm
return
;;
esac
done
}

function configinfo(){
read -r -p "请输入OSS容器名：" bucketname
read -r -p "请输入AccessKeyId：" id
read -r -p "请输入AccessKey：" key
echo "$bucketname":"$id":"$key" | sudo tee /etc/passwd-ossfs
sudo chmod 640 /etc/passwd-ossfs
sed -i "2 c\\bucketname=$bucketname" config.ini
}

function setRegion(){
    select region in 华北1（杭州） 华东2（上海） 华北1（青岛） 华北2（北京） 华北3（张家口） 华北5（呼和浩特） 华南1（深圳） 华南2（河源） 西南1（成都） 香港 其他地区
do
case $region in
"华北1（杭州）")
url=oss-cn-hangzhou.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"华东2（上海）")
url=oss-cn-shanghai.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"华北1（青岛）")
url=oss-cn-qingdao.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"华北2（北京）")
url=oss-cn-beijing.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"华北3（张家口）")
url=oss-cn-zhangjiakou.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"华北5（呼和浩特）")
url=oss-cn-huhehaote.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"华南1（深圳）")
url=oss-cn-shenzhen.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"华南2（河源）")
url=oss-cn-heyuan.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"西南1（成都）")
url=oss-cn-chengdu.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"香港")
url=oss-cn-hongkong.aliyuncs.com
sed -i "4 c\\url=$url" config.ini
return
;;
"其他地区")
read -r -p "请输入Endpoint地址：" url
sed -i "4 c\\url=$url" config.ini
return
;;
esac
done
}

function configpath(){
    mkdir -p OSS
    echo "云盘已映射到~/OSS/"
}

function mount(){
    sudo ossfs "$bucketname" ./OSS/ -ourl=http://"$url"
}

function configall(){
    echo "检测到你还没有配置OSS相关信息，下面开始引导配置"
    configinfo
    setRegion
    configpath
    mount
    lock=1
    sed -i "6 c\\lock=1" config.ini
}
echo "A Simple Aliyun OSS Tool Ver1.1"

if [ ! -f "/etc/passwd-ossfs" ]; then
install
configall
fi

if [ $lock = 0 ] ; then
configall
fi

select menu in 挂载 OSS云盘GUI文件管理器 上传文件 下载文件 更改AccessID与Key 更改地域 卸载OSS 退出
do
case $menu in 
"挂载")
configpath
mount
;;
"OSS云盘GUI文件管理器")
echo "左侧为远端云盘目录，右端为当前目录，使用空格键在两个窗格间来回切换"
echo "使用左右方向键切换上下级菜单，使用上下方向键选择当前目录文件"
echo "使用dd命令可以删除选中的远端或本地的文件"
echo "上传与下载：使用yy选中所需操作文件，进入目标目录后按p粘贴（从云盘到本地环境为下载，从本地环境到云盘为上传）"
echo "退出方法与vi使用q模式退出相同"
read
sudo vifm OSS ~
;;
"上传文件")
read -r -p "请输入需要上传的文件路径（可输入多个文件批量上传）：" fileurl
read -r -p "请输入远端OSS的存放路径（若不存在则自动创建目录）：" ossurl
if [ ! -d "$ossurl" ]; then
mkdir "$ossurl"
fi
cp "$fileurl" ./OSS$ossurl
;;
"下载文件")
read -r -p "请输入远端OSS文件的存放路径（可输入多个文件批量下载）：" ossurl
read -r -p "请输入需要下载路径（若不存在则自动创建目录）：" fileurl
if [ ! -d "$fileurl" ]; then
mkdir "$fileurl"
fi
cp ./OSS$ossurl "$fileurl"
;; 
"更改AccessID与Key")
configinfo
mount
;;
"更改地域")
setRegion
mount
;;
"卸载OSS")
sudo fusermount -u ./OSS/
;;
"退出")
exit
;;
esac
done
