#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

check_root

if [ -z "$SOLUTION_FILE" ]; then
  cat /dev/null > ./solution.txt
  SOLUTION_FILE="./solution.txt"
fi


declare -a new_lb_check=$(get_dist_native_list | egrep '^(keepalived|haproxy|piranha|ipvsadm)$')

if [[ "${new_lb_check[@]}" =~ "ipvsadm" ]];then
  if [[ "${new_lb_check[@]}" =~ "piranha" ]];then
     echo "You have installed a piranha package on your system. This is a no longer supported load balancer 
solution. Install keepalived and haproxy packages for Red Hat Enterprise Linux 7 compatible load balancer support." >> $SOLUTION_FILE
     log_high_risk "Run 'yum install keepalived haproxy' for Red Hat Enterprise Linux 7 compatible load balancer support."
     exit_fail
  else
     if [[ "${new_lb_check[@]}" =~ "keepalived" ]] && [[ "${new_lb_check[@]}" =~ "haproxy" ]];then
       echo "Load balancer support on this system is fully compatible with Red Hat Enterprise Linux 7." >> $SOLUTION_FILE
       exit_pass
     elif [[ "${new_lb_check[@]}" =~ "keepalived" ]] ;then
       echo "Your system has full support for Red Hat Enterprise Linux 7 compatible LVS based load balancer. For tcp/http based load balancer and proxy install haproxy package." >> $SOLUTION_FILE
       log_none_risk "For tcp/http based load balancer and proxy run 'yum install haproxy'."
       exit_informational
     elif [[ "${new_lb_check[@]}" =~ "haproxy" ]] ;then
       echo "You have installed haproxy tcp/http based load balancer and proxy. You have installed ipvsadm LVS based load balancer. If you want to implement an additional layer for a health check and failover handling, install a keepalived package" >> $SOLUTION_FILE
       log_none_risk "For a health check and failover handling of your LVS based load balancer run 'yum install keepalived'."
       exit_informational
     else
       echo "You have installed ipvsadm LVS based load balancer. If you want to implement an additional layer for a health check and failover handling, install a keepalived package. You can install a haproxy package for tcp/http based load balancer and proxy" >> $SOLUTION_FILE
       log_none_risk "For a health check and failover handling run 'yum install keepalived'. For tcp/http based load balancer and proxy run 'yum install haproxy'."
       exit_informational
     fi
  fi
elif [[ "${new_lb_check[@]}" =~ "haproxy" ]] ;then
    if [[ "${new_lb_check[@]}" =~ "keepalived" ]] ;then
  echo "You have installed haproxy tcp/http based load balancer and proxy. If you also want to implement LVS based load balancer, install an ipvsadm package" >> $SOLUTION_FILE  
  log_none_risk "For LVS based Load Balancer run 'yum install ipvsadm'"
  exit_informational
    else
  echo "You have installed haproxy tcp/http based load balancer and proxy. If you also want to implement LVS based load balancer, install ipvsadm and keepalived packages" >> $SOLUTION_FILE  
  log_none_risk "For LVS based Load Balancer run 'yum install ipvsadm keepalived'"
  exit_informational
  fi
else

   exit_not_applicable
fi
