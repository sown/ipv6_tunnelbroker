#!/bin/bash
d=`dirname $0`
dir=`cd $d/../; pwd`
ipv6_route=`grep "iroute-ipv6" $dir/ccd/${common_name} | awk -F ' ' '{print $2}'`
sudo /sbin/ip -6 route add ${ipv6_route} via ${ifconfig_pool_remote_ip6}
