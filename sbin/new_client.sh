#!/bin/bash
d=`dirname $0`
dir=`cd $d/../; pwd`
cn_prefix="IPv6_Tunnelbroker_Client_"
config_dir="ipv6tb"
if [ -f ${dir}/sbin/settings.sh ]; then
	source ${dir}/sbin/settings.sh
fi
cn_suffix="_Cert"
d=`dirname $0`
dir=`cd $d/../; pwd`

# Work out new ID and CommonName (CN)
last_cn=`tail -n 1 $dir/userlist.txt`
last_id=`echo $last_cn | awk -F '_' '{print $5}'`
id=`expr $last_id + 1`
idhex=`printf "%02x" $id`
cn="${cn_prefix}${id}${cn_suffix}"

# Get attributes for CSR subject line
c=`cat $dir/ca/intermediate/openssl.cnf | grep "^countryName_default" | awk -F '=' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
st=`cat $dir/ca/intermediate/openssl.cnf | grep "^stateOrProvinceName_default" | awk -F '=' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
l=`cat $dir/ca/intermediate/openssl.cnf | grep "^localityName_default" | awk -F '=' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
o=`cat $dir/ca/intermediate/openssl.cnf | grep "^0.organizationName_default" | awk -F '=' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
ou=`cat $dir/ca/intermediate/openssl.cnf | grep "^organizationalUnitName_default" | awk -F '=' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
emailAddress=`cat $dir/ca/intermediate/openssl.cnf | grep "^emailAddress_default" | awk -F '=' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`

# Generate client key, CSR and certificate
openssl genrsa -out ${dir}/ca/intermediate/private/client${id}.key.pem 4096
chmod 400 ${dir}/ca/intermediate/private/client${id}.key.pem
openssl req -config ${dir}/ca/intermediate/openssl.cnf -key ${dir}/ca/intermediate/private/client${id}.key.pem -subj "/C=$c/ST=$st/L=$l/O=$o/OU=$ou/CN=$cn/emailAddress=$emailAddress" -new -sha256 -out ${dir}/ca/intermediate/csr/client${id}.csr.pem
openssl ca -config ${dir}/ca/intermediate/openssl.cnf -extensions usr_cert -days 1000 -notext -md sha256 -in ${dir}/ca/intermediate/csr/client${id}.csr.pem -out ${dir}/ca/intermediate/certs/client${id}.cert.pem

if [ ! -f ${dir}/ca/intermediate/certs/client${id}.cert.pem ]; then
	echo "Certificate not generated from client with ID $id"
	rm ${dir}/ca/intermediate/private/client${id}.key.pem
	rm ${dir}/ca/intermediate/csr/client${id}.csr.pem
	exit 1
fi

# Generate client-side config
cat <<EOF > $dir/clients/config/client${id}.conf
client
daemon
dev tun
proto tcp
log-append /var/log/${config_dir}_client${id}.log
remote tunnelbroker.ecs.soton.ac.uk 1194
remote tunnelbroker.ecs.soton.ac.uk 443
remote 152.78.180.112 1194
remote 152.78.180.112 443
resolv-retry infinite
nobind
user nobody
group nogroup
persist-key
persist-tun
ca /etc/openvpn/${config_dir}/ca-chain.cert.pem
cert /etc/openvpn/${config_dir}/client${id}.cert.pem
key /etc/openvpn/${config_dir}/client${id}.key.pem
remote-cert-tls server
tls-auth /etc/openvpn/${config_dir}/ta.key 1
auth SHA256
cipher AES-256-CBC
float
verb 1
script-security 2
EOF

# Generate client-side config
cat <<EOF | /usr/bin/unix2dos > $dir/clients/config/client${id}.ovpn
client
dev tun
proto tcp
log-append client${id}.log
remote tunnelbroker.ecs.soton.ac.uk 1194
remote tunnelbroker.ecs.soton.ac.uk 443
remote 152.78.180.112 1194
remote 152.78.180.112 443
resolv-retry infinite
nobind
user nobody
group nogroup
persist-key
persist-tun
ca ca-chain.cert.pem
cert client${id}.cert.pem
key client${id}.key.pem
remote-cert-tls server
tls-auth ta.key 1
auth SHA256
cipher AES-256-CBC
float
verb 1
script-security 2
EOF

cat <<EOF > $dir/clients/config/client${id}.uci
config openvpn '${config_dir}'
    option enable '1'
    option client '1'
    option daemon '1'
    option dev 'tun'
    option proto 'tcp'
    option log_append /var/log/${config_dir}_client${id}.log
    list remote 'tunnelbroker.ecs.soton.ac.uk 1194'
    list remote 'tunnelbroker.ecs.soton.ac.uk 443'
    list remote '152.78.180.112 1194'
    list remote '152.78.180.112 443'
    option resolv_retry 'infinite'
    option nobind
    option user 'nobody'
    option group 'nogroup'
    option persist_key '1'
    option persist_tun '1'
    option ca '/etc/openvpn/${config_dir}/ca-chain.cert.pem'
    option cert '/etc/openvpn/${config_dir}/client6.cert.pem'
    option key '/etc/openvpn/${config_dir}/client6.key.pem'
    option remote_cert_tls 'server'
    option tls_auth '/etc/openvpn/${config_dir}/ta.key 1'
    option auth 'SHA256'
    option cipher 'AES-256-CBC'
    option float '1'
    option verb '1'
    option script_security '2'
EOF


# Generate client-side tarball for deployment
tmp_dir=`mktemp -p /tmp/ -d ${config_dir}.XXXXXX`
mkdir ${tmp_dir}/${config_dir}
cp $dir/clients/config/client${id}.conf ${tmp_dir}/${config_dir}/
cp $dir/clients/config/client${id}.ovpn ${tmp_dir}/${config_dir}/
cp $dir/clients/config/client${id}.uci ${tmp_dir}/${config_dir}/
cp $dir/ta.key ${tmp_dir}/ecstb6/
cp $dir/ca/intermediate/certs/ca-chain.cert.pem ${tmp_dir}/${config_dir}/
cp $dir/ca/intermediate/certs/client${id}.cert.pem ${tmp_dir}/${config_dir}/
cp $dir/ca/intermediate/private/client${id}.key.pem ${tmp_dir}/${config_dir}/
cd ${tmp_dir}
tar -czf $dir/clients/tarballs/client${id}.tar.gz ${config_dir}/
cd ${dir}
\rm $tmp_dir/${config_dir}/*
rmdir $tmp_dir/${config_dir}/
rmdir $tmp_dir/

# Generate client-config-dir configuration
cat <<EOF > $dir/ccd/$cn
ifconfig-ipv6-push 2001:630:d0:f300::10${idhex}
iroute-ipv6 2001:630:d0:f3${idhex}::/64
EOF

# Add new client CN to userlist 
echo $cn >> $dir/userlist.txt

echo -e "\n----------------------------------------------------------------------\nClient configuration with CN '$cn' has been created.\nA client-side tarball can be found at  ${dir}/clients/tarballs/client${id}.tar.gz\n\n"
