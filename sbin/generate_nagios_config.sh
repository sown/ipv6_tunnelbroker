#!/bin/bash
d=`dirname $0`
dir=`cd $d/../; pwd`
cn_prefix="IPv6_Tunnelbroker_Client_"
config_dir="ipv6tb"
if [ -f ${dir}/sbin/settings.sh ]; then
        source ${dir}/sbin/settings.sh
fi

# TODO: Currently bespoke for adding to an existing Icinga instance.  Re-code to be more generic and include command and host definitions.
for client in `grep "^V" ${dir}/ca/intermediate/index.txt | grep -o "${cn_prefix}.*"`; do
	id=`echo ${client} | sed "s/^${cn_prefix}//" | sed "s/_Cert$//"`
	monitor=`cat ${dir}/usage.txt | grep -P "^${id}\t" | awk 'BEGIN{FS="\t"}{print $7}'`
	if [ "$monitor" == "Yes" ]; then
		echo "# $client
define service {
	host_name   		TUNNELBROKER
	service_description     TUNNEL6-client${id}
	use			vpnserver
	check_command     	check_tunnel6!${id}
	notifications_enabled	0
}

define service {
	host_name   		TUNNELBROKER
	service_description     TUNNEL6CERT-client${id}
	use			nodecert
	check_command     	check_cert!intermediate/certs/client${id}.cert.pem
}

";
	fi
done
