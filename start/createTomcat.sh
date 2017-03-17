#!/bin/bash
#docker run -d -i -t  -e "INSTANCE_NAME=ues-ws" -e "ENV_INFO=func111docker" -e "CONTEXT_NAME=ues-ws" -e "GIT_NAME=fj338_ues-ws" -e "INSTANCE_CMD=fj338_ues-ws_func111_build_20161216.1" --add-host git.vfinance.cn:10.65.213.16  -p $PORT:8080 vftomcat8/tomcat
#usage(){
#        echo -e "\nusage: $0 INSTANCE_NAME ENV_INFO CONTEXT_NAME GIT_NAME INSTANCE_CMD\n"
#}
#if [ $# != 5 ];then
#        usage
#        exit 0
#fi
echo $INSTANCE_NAME $ENV_INFO $CONTEXT_NAME $GIT_NAME $INSTANCE_CMD
GIT_TAG=$INSTANCE_CMD
CATALINA_HOME=/opt/app/$INSTANCE_NAME
gitClone(){
        if [ ! -d /opt/applications/$1/.git ]; then
                mkdir -p /opt/applications/$1
                git clone git://git.vfinance.cn/$1.git /opt/applications/$1;
        fi
        if [[ $1 == fj* ]]
        then
          cd /opt/applications/$1&&git clean -f -d&&git reset --hard&&git fetch&&git reset --merge $GIT_TAG;
        fi
}

addInstance() {
        echo "add tomcat instance..."
        mv /opt/app/tomcat/ $CATALINA_HOME
        cd $CATALINA_HOME/conf
        rm -f context.xml
        ln -s /opt/applications/env_conf_app_$ENV_INFO/tomcat/$INSTANCE_NAME/conf/context.xml ./
        sed -i '/JAVA_OPTS=\"-server/d' $CATALINA_HOME/bin/catalina.sh
        sed -i '/JAVA_OPTS=\"-Xmx/d' $CATALINA_HOME/bin/catalina.sh
        sed '2 iJAVA_OPTS="-Xmx512m -Xms512m -Xmn256m -Xss256k -XX:PermSize=64m -XX:MaxPermSize=128m -XX:+UseConcMarkSweepGC -XX:ParallelGCThreads=8 -XX:CMSFullGCsBeforeCompaction=0 -XX:+UseCMSCompactAtFullCollection -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=7 -XX:GCTimeRatio=19 -Xnoclassgc -XX:+DisableExplicitGC -XX:+UseParNewGC -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=70 -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath='"$CATALINA_HOME"'/logs/java_heapdump.hprof"' -i $CATALINA_HOME/bin/catalina.sh
#       sed '2 iJAVA_OPTS="-Xmx1024m -Xms1024m -Xmn480m -Xss256k -XX:PermSize=64m -XX:MaxPermSize=128m -XX:+UseConcMarkSweepGC -XX:ParallelGCThreads=8 -XX:CMSFullGCsBeforeCompaction=0 -XX:+UseCMSCompactAtFullCollection -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=7 -XX:GCTimeRatio=19 -Xnoclassgc -XX:+DisableExplicitGC -XX:+UseParNewGC -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=70 -XX:SoftRefLRUPolicyMSPerMB=0"' -i $tomcatDir/$INSTANCE_NAME/bin/catalina.sh
        echo add finlog
        cp -r /opt/applications/docker_tools/docker_tools/finlog $CATALINA_HOME
#       sed -i '/finlog/d' $tomcatDir/$instance_name/bin/catalina.sh
        sed -i '/CATALINA_OPTS=\"$CATALINA_OPTS -javaagent:'"$CATALINA_HOME"'\/finlog/d' $CATALINA_HOME/bin/catalina.sh
        sed '6 iCATALINA_OPTS="$CATALINA_OPTS -javaagent:'"$CATALINA_HOME"'/finlog/finlog.jar"; export CATALINA_OPTS' -i $CATALINA_HOME/bin/catalina.sh
        sed -i "s/app=vfinance/app=$ENV_INFO\.$INSTANCE_NAME/g" $CATALINA_HOME/finlog/log.properties
}
addContext() {
        echo "add tomcat context..."
        app_path=$CATALINA_HOME/webapps/
        if [ ! -d "$app_path" ]; then
                mkdir -p $app_path
        fi
        git_path=/opt/applications/$GIT_NAME
        if [ $(ls $git_path -F | grep '/$' |wc -l |awk '{print $1}') -eq 1 ]; then
                contextPath=$git_path/`ls $git_path -F | grep '/$'`
                rm -rf $app_path*
                ln -s  $contextPath $app_path$CONTEXT_NAME;
        else
                echo "ERROR $git_path sub directory not only!!!"
                exit 1
        fi
}

addConfig() {
        if [ -d /opt/applications/env_conf_$ENV_INFO ]; then
                mkdir -p /opt/pay
                ln -s  /opt/applications/env_conf_$ENV_INFO/config /opt/pay/
        else
                echo "ERROR /opt/applications/env_conf_$ENV_INFO NOT EXIST,check git clone"
                exit 1
        fi
}
gitClone env_conf_$ENV_INFO
gitClone env_conf_app_$ENV_INFO
gitClone $GIT_NAME
addInstance
addContext
addConfig
sh $CATALINA_HOME/bin/catalina.sh start