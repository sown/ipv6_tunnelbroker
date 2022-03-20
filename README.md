# IPv6 Tunnelbroker

The IPv6 Tunnelbroker is a project to provide fully routed IPv6 connectivity in situations where it is difficult for ISPs to provide it.  Several projects for which we want to use this IPv6 tunnelbroker, include [enviromental sensing in the Cairngorms](http://mountainsensing.org/), [monitor glacier behaviour using sensor networks in Iceland](http://glacsweb.org) and providing IPv6 for a [mobile Cyber Rhino](http://www.ericatherhino.org).

OpenVPN is the application of choice to build this tunnelbroker around.

## Instructions for Building Certificate Authorities
These instructions are broadly based on those found at [https://jamielinux.com/docs/openssl-certificate-authority/](https://jamielinux.com/docs/openssl-certificate-authority/).

All commands are run from the /etc/openvpn/ipv6\_tunnelbroker/ca/ directory unless otherwise stated.

### Creating Root Key and Certificate

1. Create key /etc/openvpn/ipv6\_tunnelbroker/ca/private/ca.key.pem and set permissions (key size 4096 bits, passphrase encoded using AES-256 encryption):
```
openssl genrsa -aes256 -out private/ca.key.pem 4096
chmod 400 private/ca.key.pem
```

2. Create certificate /etc/openvpn/ipv6\_tunnelbroker/ca/certs/ca.cert.pem and set permissions (certificate length 20 years, using SHA-256 and configuration options in v3\_ca section of /etc/openvpn/ipv6\_tunnelbroker/ca/openssl.conf and default attributes but with Common Name "IPv6\_Tunnelbroker\_Root\_CA"):
```
openssl req -config openssl.cnf -key private/ca.key.pem -new -x509 -days 7300 \
    -sha256 -extensions v3_ca -out certs/ca.cert.pem
chmod 444 certs/ca.cert.pem
```

### Creating Intermediate Key and Certificate

1. Create key /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/private/intermediate.key.pem and set permissions (key size 4096 bits, passphrase encoded using AES-256 encryption):
```
openssl genrsa -aes256 -out intermediate/private/intermediate.key.pem 4096
chmod 400 intermediate/private/intermediate.key.pem
```

2. Create CSR /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/csr/intermediate.csr.pem using intermediate.key.pem just created and configuration from /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/openssl.cnf, (using the default attributes but with Common Name "IPv6\_Tunnelbroker\_Intermediate\_CA"):
```
openssl req -config intermediate/openssl.cnf -new -sha256 \
    -key intermediate/private/intermediate.key.pem \ 
    -out intermediate/csr/intermediate.csr.pem
```

3. Sign CSR intermediate.csr.pem to create /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/certs/intermediate.cert.pem (certificate length 10 years, using SHA-256 and configuration options in v3\_intermediate\_ca section of /etc/openvpn/ipv6\_tunnelbroker/ca/openssl.conf):
```
openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days 3650 \
    -notext -md sha256 -in intermediate/csr/intermediate.csr.pem \
    -out intermediate/certs/intermediate.cert.pem
```

### Creating a CRL for Intermediate Certificate Authority 

Create a CRL for the Intermediate certificate using the configuration options in /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/openssl.conf
```
openssl ca -config intermediate/openssl.cnf -gencrl \ 
    -out intermediate/crl/intermediate.crl.pem
```

When the CRL expires the same command can be used to replace it.

### Creating OpenVPN Server Key and Certificate

This assumes using Tun rather than Tap interface, meaning only a single OpenVPN server configuration is needed.

1. Create key /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/private/server.key.pem (key size 4096 bits, no passphrase):
```
openssl genrsa -out intermediate/private/server.key.pem 4096
```

2. Create CSR /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/csr/server.csr.pem using server.key.pem just created and configuration from /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/openssl.cnf, (using the default attributes but with Common Name "IPv6\_Tunnelbroker\_Server\_Cert"):
```
openssl req -config intermediate/openssl.cnf \
    -key intermediate/private/server.key.pem -new -sha256 \ 
    -out intermediate/csr/server.csr.pem
```

3. Sign CSR server.csr.pem to create /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/certs/server.cert.pem (certificate length just over 3 years, using SHA-256 and configuration options in server\_cert section of /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/openssl.conf):
```
openssl ca -config intermediate/openssl.cnf -extensions server_cert \
    -days 1000 -notext -md sha256 -in intermediate/csr/server.csr.pem \
    -out intermediate/certs/server.cert.pem
```

### Creating OpenVPN Client Key and Certificate

1. Create key /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/private/client1.key.pem (key size 4096 bits, no passphrase):
```
openssl genrsa -out intermediate/private/client1.key.pem 4096
```

2. Create CSR /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/csr/client1.csr.pem using client1.key.pem just created and configuration from /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/openssl.cnf, (using the default attributes but with Common Name "IPv6\_Tunnelbroker\_Client1\_Cert"):
```
openssl req -config intermediate/openssl.cnf \
    -key intermediate/private/client1.key.pem -new -sha256 \
    -out intermediate/csr/client1.csr.pem
```
3. Sign CSR client1.csr.pem to create /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/certs/client1.cert.pem (certificate length just over 3 years, using SHA-256 and configuration options in usr\_cert section of /etc/openvpn/ipv6\_tunnelbroker/ca/intermediate/openssl.conf):
```
openssl ca -config intermediate/openssl.cnf -extensions usr_cert \
    -days 1000 -notext -md sha256 -in intermediate/csr/client1.csr.pem \ 
    -out intermediate/certs/client1.cert.pem
```
