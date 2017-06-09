= IPv6 Tunnelbroker =

Based on instructions found at https://jamielinux.com/docs/openssl-certificate-authority/

All commands are run from the /etc/openvpn/tunnelbroker/ca/ directory unless otherwise stated.


== Creating Root Key and Certificate ==

1. Create key /etc/openvpn/tunnelbroker/ca/private/ca.key.pem and set permissions (key size 4096 bits, passphrase encoded using AES-256 encryption):

	openssl genrsa -aes256 -out private/ca.key.pem 4096
	chmod 400 private/ca.key.pem

2. Create certificate /etc/openvpn/tunnelbroker/ca/certs/ca.cert.pem and set permissions (certificate length 20 years, using SHA-256 and configuration options in v3_ca section of /etc/openvpn/tunnelbroker/ca/openssl.conf and default attributes but with Common Name "IPv6_Tunnelbroker_Root_CA"):

	openssl req -config openssl.cnf -key private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out certs/ca.cert.pem
	chmod 444 certs/ca.cert.pem


== Creating Intermediate Key and Certificate ==

1. Create key /etc/openvpn/tunnelbroker/ca/intermediate/private/intermediate.key.pem and set permissions (key size 4096 bits, passphrase encoded using AES-256 encryption):

        openssl genrsa -aes256 -out intermediate/private/intermediate.key.pem 4096
        chmod 400 intermediate/private/intermediate.key.pem

2. Create CSR /etc/openvpn/tunnelbroker/ca/intermediate/csr/intermediate.csr.pem using intermediate.key.pem just created and configuration from /etc/openvpn/tunnelbroker/ca/intermediate/openssl.cnf, (using the default attributes but with Common Name "IPv6_Tunnelbroker_Intermediate_CA"):

	openssl req -config intermediate/openssl.cnf -new -sha256 -key intermediate/private/intermediate.key.pem -out intermediate/csr/intermediate.csr.pem

3. Sign CSR intermediate.csr.pem to create /etc/openvpn/tunnelbroker/ca/intermediate/certs/intermediate.cert.pem (certificate length 10 years, using SHA-256 and configuration options in v3_intermediate_ca section of /etc/openvpn/tunnelbroker/ca/openssl.conf):
   
	openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in intermediate/csr/intermediate.csr.pem -out intermediate/certs/intermediate.cert.pem


== Create CRL for Intermediate Certificate Authority ==

Create a CRL for the Intermediate certificate using the configuration options in /etc/openvpn/tunnelbroker/ca/intermediate/openssl.conf

	openssl ca -config intermediate/openssl.cnf -gencrl -out intermediate/crl/intermediate.crl.pem


== Creating OpenVPN Server Key and Certificate ==

This assumes using Tun rather than Tap interface, meaning only a single OpenVPN server configuration is needed.

1. Create key /etc/openvpn/tunnelbroker/ca/intermediate/private/server.key.pem (key size 4096 bits, no passphrase):

	openssl genrsa -out intermediate/private/server.key.pem 4096

2. Create CSR /etc/openvpn/tunnelbroker/ca/intermediate/csr/server.csr.pem using server.key.pem just created and configuration from /etc/openvpn/tunnelbroker/ca/intermediate/openssl.cnf, (using the default attributes but with Common Name "IPv6_Tunnelbroker_Server_Cert"):

	openssl req -config intermediate/openssl.cnf -key intermediate/private/server.key.pem -new -sha256 -out intermediate/csr/server.csr.pem

3. Sign CSR server.csr.pem to create /etc/openvpn/tunnelbroker/ca/intermediate/certs/server.cert.pem (certificate length just over 3 years, using SHA-256 and configuration options in server_cert section of /etc/openvpn/tunnelbroker/ca/intermediate/openssl.conf):

	openssl ca -config intermediate/openssl.cnf -extensions server_cert -days 1000 -notext -md sha256 -in intermediate/csr/server.csr.pem -out intermediate/certs/server.cert.pem


== Creating OpenVPN Client Key and Certificate ==

1. Create key /etc/openvpn/tunnelbroker/ca/intermediate/private/client1.key.pem (key size 4096 bits, no passphrase):

        openssl genrsa -out intermediate/private/client1.key.pem 4096

2. Create CSR /etc/openvpn/tunnelbroker/ca/intermediate/csr/client1.csr.pem using client1.key.pem just created and configuration from /etc/openvpn/tunnelbroker/ca/intermediate/openssl.cnf, (using the default attributes but with Common Name "IPv6_Tunnelbroker_Client1_Cert"):

        openssl req -config intermediate/openssl.cnf -key intermediate/private/client1.key.pem -new -sha256 -out intermediate/csr/client1.csr.pem

3. Sign CSR client1.csr.pem to create /etc/openvpn/tunnelbroker/ca/intermediate/certs/client1.cert.pem (certificate length just over 3 years, using SHA-256 and configuration options in usr_cert section of /etc/openvpn/tunnelbroker/ca/intermediate/openssl.conf):

        openssl ca -config intermediate/openssl.cnf -extensions usr_cert -days 1000 -notext -md sha256 -in intermediate/csr/client1.csr.pem -out intermediate/certs/client1.cert.pem

