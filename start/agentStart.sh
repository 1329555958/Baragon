#!/bin/bash
kill -9 `cat agent.pid |awk '{print $1}'`
nohup java -jar ../baragon-agent/BaragonAgentService-0.5.0-SNAPSHOT-shaded.jar server agentConfig.yml>agent.log 2>&1 &
echo $!>agent.pid
tail -f agent.log

