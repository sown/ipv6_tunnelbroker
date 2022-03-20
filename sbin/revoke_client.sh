#!/bin/bash
if [ `whoami` != "root" ]; then
        echo "$0 must be run as root or using sudo."
        exit 1
fi
re='^[1-9][0-9]*$'
if [ $# != 1 ]; then
	echo -e "No Client ID provided.\n\nUsage: ./revoke_client.sh <client_id>\nE.g. ./revoke_client.sh 4\n"
	exit 1
fi
id=$1
d=`dirname $0`
dir=`cd $d/../; pwd`
if ! [[ $id =~ $re ]]; then
	echo -e "Client ID is not a positive integer.\n\nUsage: ./revoke_client.sh <client_id>\nE.g. ./revoke_client.sh 4\n"
	exit 1
elif [ ! -f $dir/ca/intermediate/certs/client${id}.cert.pem ]; then
	echo -e "Client with ID ${id} does not exist.  (No certficate at at $dir/ca/intermediate/certs/client${id}.cert.pem).\n"
	exit 1
fi
openssl ca -config ${dir}/ca/intermediate/openssl.cnf -revoke ${dir}/ca/intermediate/certs/client${id}.cert.pem || { echo -e "\n\nCould not revoke certificate for Client with ID ${id}.  Maybe the passphrase is wrong or the certificate is already revoked ... exiting!\n"; exit 1; }
openssl ca -config ${dir}/ca/intermediate/openssl.cnf -gencrl -out ${dir}/ca/intermediate/crl/intermediate.crl.pem || { echo -e "\n\nCould not regenerate CRL for Intermediate CA ... exiting!\n"; exit 1; }
echo -e "\n\nSuccessfully revoked certificate for client with ID ${id}!\n"
