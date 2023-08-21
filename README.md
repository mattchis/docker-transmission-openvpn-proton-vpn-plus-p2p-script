# docker-transmission-openvpn-proton-vpn-plus-p2p-script

This script maps the exposed port that is opened by the Proton VPN Plus service to Transmission.

## Requirements
- A working transmission-openvpn Docker continer from [haugene](https://github.com/haugene/docker-transmission-openvpn)
- Proton VPN Plus Account
- Proton OpenVPN P2P configuration file from your [account](https://account.proton.me/u/0/vpn/OpenVpnIKEv2)
	- Note: The P2P connections are the ones with the icon that has two arrows pointing left and right
	- Besure that the platform **GNU/Linux** is selected

## Setup
- Place the Proton OpenVPN P2P configuration file to the **/etc/openvpn/custom/** folder
	- Note: Make a persistant docker volume to **/etc/openvpn/custom/**. This will mak it easier to update.
- Place the update-port.sh script from this repository to the **/etc/openvpn/custom/** folder
	- Note: Make sure you chmod this file to be executable
- Change OPENVPN_PROVIDER value to **custom**
- Change OPENVPN_CONFIG value to the name of the Proton OpenVPN P2P configuration file, without the extension (.ovpn)
- Append +pmp to your username

## Running
- Restart the docker container
- Check to see if port is open in transmission web GUI by going to **Edit preferences -> Network**