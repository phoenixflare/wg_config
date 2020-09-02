**This is a part of project:**

https://github.com/adrianmihalko/raspberrypiwireguard

Be sure to read this first.


##############################################################################




This is a simple wireguard VPN user management script using on VPN server.
Client config file and qrcode are generated.



### Dependency

* wireguard
* qrencode

### Config
The wireguard default config directory is /etc/wireguard.
The script config file is wg.def, create and edit it according to wg.def.sample.
You can generate the public key and private key with command `wg genkey | tee > prikey | wg pubkey > pubkey`.

### Usage

Running as root.

#### Start wireguard

```bash
./init.sh
```

#### Add a user

```bash
./user.sh -a alice
```

This will generate a client conf and qrcode in current directory which name is alice
and add alice to the wg config.

#### Delete a user

```bash
./user.sh -d alice
```
This will delete the alice directory and delete alice from the wg config.

#### View a user

```bash
./user.sh -v alice
```
This will show generated QR codes.


#### Clear all

```bash
./config.sh -d
```


#### Reload wireguard configuration
```bash
./config.sh -r
```


# Packet forwarding and ip address limiting

By default, data from wireguard peers cannot access the LAN.
To allow peers to access the LAN, uncomment the following line in **/etc/sysctl.conf**
```bash
net.ipv4.ip_forward=1
```
A restart is required after this has been enabled.


### Whitelist and blacklist
The default iptable rules for wireguard will allow all traffic from the peers to the LAN.
If you wish to limit access to certain addresses, add the LAN range to the *server.conf.blacklist*.
IP addresses added to *server.conf.whitelist* will be forward from the peers.

The following will only allow 192.168.1.100 and 192.168.1.48 and prevent any other access to the LAN
###### server.conf.whitelist
```bash
192.168.1.48/32
192.168.1.100/32
```

###### server.conf.blacklist
```bash
192.168.1.0/24
```

When these files are changed, a reload of the wireguard interface is required.
```bash
./config.sh -r
```
