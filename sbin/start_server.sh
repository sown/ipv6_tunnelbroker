#!/bin/bash
d=`dirname $0`
dir=`cd $d; pwd`
openvpn --config $dir/../server.conf 
