#!/bin/bash 

source /etc/openvpn/utils.sh

. /etc/transmission/environment-variables.sh

###### Settings ######
TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt
transmission_username=$(head -1 ${TRANSMISSION_PASSWD_FILE})
transmission_passwd=$(tail -1 ${TRANSMISSION_PASSWD_FILE})
transmission_settings_file=${TRANSMISSION_HOME}/settings.json

sleep 5

###### ProtonVPN Variables ######
user=$(sed -n 1p /config/openvpn-credentials.txt)
pass=$(sed -n 2p /config/openvpn-credentials.txt)

###### Install natpmpc ######
install_dep () {
  echo "################################################"
  echo "    Running Repo Update and Install natpmpc     "
  echo "################################################"
  echo ""
  apt-get update
  apt-get install -y natpmpc
}

###### ProtonVPN P2P Get Port ######
bind_port () {
  echo "################################################"
  echo "       Acquiring Open Port on Proton VPN        "
  echo "################################################"
  echo ""
  get_port=$(natpmpc -a 0 0 udp | sed -e '/port /!d; s/.*port \(.*\) protocol.*/\1/')
  echo "Reserved Port: $get_port  $(date)"
  echo ""
}

###### ProtonVPN Set Port on Transmission ######
bind_trans () {
  echo "################################################"
  echo "      Checking if Transmission is Running       "
  echo "################################################"
  echo ""
  new_port=$get_port

  # Check if transmission remote is set up with authentication
  auth_enabled=$(grep 'rpc-authentication-required\"' "$transmission_settings_file" \
                     | grep -oE 'true|false')

  if [[ "true" = "$auth_enabled" ]]
    then
    echo "transmission auth required"
    myauth="--auth $transmission_username:$transmission_passwd"
  else
      echo "transmission auth not required"
      myauth=""
  fi

  # make sure transmission is running and accepting requests
  echo "waiting for transmission to become responsive"
  until torrent_list="$(transmission-remote $TRANSMISSION_RPC_PORT $myauth -l)"; do sleep 10; done
  echo "transmission became responsive"
  output="$(echo "$torrent_list" | tail -n 2)"
  echo "$output"
  echo ""

  # get current listening port
  transmission_peer_port=$(transmission-remote $TRANSMISSION_RPC_PORT $myauth -si | grep Listenport | grep -oE '[0-9]+')
  if [[ "$new_port" != "$transmission_peer_port" ]]; then
    if [[ "true" = "$ENABLE_UFW" ]]; then
      echo "################################################"
      echo "           Setting up UFW Port Rules            "
      echo "################################################"
      echo ""
      echo "Update UFW rules before changing port in Transmission"

      echo "denying access to $transmission_peer_port"
      ufw deny "$transmission_peer_port"

      echo "allowing $new_port through the firewall"
      ufw allow "$new_port"
      echo ""
    fi

    echo "################################################"
    echo "   Setting up Transmission with Acquired Port   "
    echo "################################################"
    echo ""

    echo "setting transmission port to $new_port"
    transmission-remote ${TRANSMISSION_RPC_PORT} ${myauth} -p "$new_port"

    echo "Checking port..."
    sleep 10
    transmission-remote ${TRANSMISSION_RPC_PORT} ${myauth} -pt
  else
    echo "################################################"
    echo "   Setting up Transmission with Acquired Port   "
    echo "################################################"
    echo ""
    echo "No action needed, port hasn't changed"
  fi
  echo ""
}

main () {
  bind_port
  bind_trans
  echo "################################################"
  echo "                 Script Details                 "
  echo "################################################"
  echo "Port: $get_port"
  echo "Entering infinite while loop"
  echo "Every 45 seconds, check port status"
  echo "################################################"
  echo ""

  while true; do
    echo "################################################"
    echo "           Keeping Port $get_port Active            "
    echo "################################################"
    date
    natpmpc -a 0 0 udp 60 && natpmpc -a 0 0 tcp 60 || { echo -e "ERROR with natpmpc command \a" ; break ; }
    echo "################################################"
    echo ""
  	sleep 45
  done
  main
}

echo "################################################"
echo " Running Proton VPN Plus P2P Update Port Script "
echo "################################################"
echo ""
install_dep
main