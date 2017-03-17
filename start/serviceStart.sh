#!/bin/bash
kill -9 `cat service.pid |awk '{print $1}'`
nohup java -jar ../baragon-master/BaragonService-0.5.0-SNAPSHOT-shaded.jar server serviceConfig.yml>service.log 2>&1 &
echo $!>service.pid
tail -f service.log
