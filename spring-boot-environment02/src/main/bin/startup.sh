#!/bin/bash

#获得当前路径
current_path=`pwd`
#获得uname 走case分支 如果 linu则第一个分支
case "`uname`" in
    Linux)#case Linux
      #$(dirname $0) 获得当前脚本的目录 $0为脚本名字 readlink -f  找出真实链接针对有符号链接的的目录 比如ll /etc/bin ->/etc/b2 执行 readlink -f /etc/bin 返回 /etc/b2
		bin_abs_path=$(readlink -f $(dirname $0))
		;;
	*) #default cd 到当前目录 通过pwd获取
		bin_abs_path=`cd $(dirname $0); pwd`
		;;
esac
#脚本目录 如 /admin/bin/..
base=${bin_abs_path}/..
#设置环境变量(全局变量) 防止中文乱码
export LANG=en_US.UTF-8
#设置环境变量(全局变量)
export BASE=$base
# if if判断文件是否存在 如果存在 则表示 存在正在启动 提示先执行stop
if [ -f $base/bin/adapter.pid ] ; then
	echo "found adapter.pid , Please run stop.sh first ,then startup.sh" 2>&2
    exit 1
fi
#如果目录不存在 则创建logs目录
if [ ! -d $base/logs ] ; then
	mkdir -p $base/logs
fi

## set java path
#-z 是否为空 为空则为真 尝试用which获得java路径
if [ -z "$JAVA" ] ; then
  JAVA=$(which java)
fi

ALIBABA_JAVA="/usr/alibaba/java/bin/java"
TAOBAO_JAVA="/opt/taobao/java/bin/java"
#如果which没获取到 尝试用上面2个默认的
if [ -z "$JAVA" ]; then
  #如果 -f FILE 存在且是一个普通文件则为真。
  if [ -f $ALIBABA_JAVA ] ; then
  	JAVA=$ALIBABA_JAVA
  elif [ -f $TAOBAO_JAVA ] ; then
  	JAVA=$TAOBAO_JAVA
  else
  	echo "Cannot find a Java JDK. Please set either set JAVA or put java (>=1.5) in your PATH." 2>&2
    exit 1
  fi
fi
#$#特殊变量 执行脚本变量个数 可参考https://www.cnblogs.com/davidshen/p/10234178.html
case "$#"
in
0 )
  ;;
2 )
  if [ "$1" = "debug" ]; then
    DEBUG_PORT=$2
    DEBUG_SUSPEND="n"
    JAVA_DEBUG_OPT="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=$DEBUG_PORT,server=y,suspend=$DEBUG_SUSPEND"
  fi
  ;;
* )
  echo "THE PARAMETERS MUST BE TWO OR LESS.PLEASE CHECK AGAIN."
  exit;;
esac
#查看jdk是否是64-bit设置不同的堆内存大小
str=`file -L $JAVA | grep 64-bit`
if [ -n "$str" ]; then
	JAVA_OPTS="-server -Xms2048m -Xmx3072m"
else
	JAVA_OPTS="-server -Xms1024m -Xmx1024m"
fi

#jvm参数设置 使用G1收集器
JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=250 -XX:+UseGCOverheadLimit -XX:+ExplicitGCInvokesConcurrent -XX:+PrintAdaptiveSizePolicy -XX:+PrintTenuringDistribution"
JAVA_OPTS=" $JAVA_OPTS -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8"
CANAL_OPTS="-DappName=canal-admin"
#这是java 启动的-classpath参数jar包
for i in $base/lib/*;
    do CLASSPATH=$i:"$CLASSPATH";
done
#设置class path启动的配置文件
CLASSPATH="$base/conf:$CLASSPATH";

echo "cd to $bin_abs_path for workaround relative path"
cd $bin_abs_path


echo CLASSPATH :$CLASSPATH
#执行启动 1>>/dev/null 2>&1 & 为忽略控制台所有输出
$JAVA $JAVA_OPTS $JAVA_DEBUG_OPT $CANAL_OPTS -classpath .:$CLASSPATH com.liqiang.springbootenvironment02.SpringBootEnvironment02Application 1>>/dev/null 2>&1 &
#Shell最后运行的后台Process的PID(后台运行的最后一个进程的 进程ID号) 输出到bin
echo $! > $base/bin/admin.pid

echo "cd to $current_path for continue"
cd $current_path