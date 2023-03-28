#!/bin/bash

function change_initiator_name(){
echo -n "$(sed -i "/InitiatorName=/c\InitiatorName=${1}" "/boot/config/plugins/iscsi-initiator/initiatorname.cfg")"
echo -n "$(iscsiadm -m node --logout)"
echo -n "$(kill $(pidof iscsid))"
echo -n "$(iscsid --config=/boot/config/plugins/iscsi-initiator/iscsid.conf --initiatorname=/boot/config/plugins/iscsi-initiator/initiatorname.cfg)"
}

function create_target(){
echo "Trying to connect to ${2}:${3}"
timeout 5 iscsiadm -m discovery -t sendtargets -p ${2}:${3} > /dev/null 2>&1
EXIT_STATUS="$?"
if [ "${EXIT_STATUS}" == 0 ]; then
  echo "Connection to ${2}:${3} successful"
  unset EXIT_STATUS
else
  echo "ERROR: Connecton to ${2}:${3} timed out"
  exit 1
fi
sleep 0.5
echo
iscsiadm -m node -T ${1} -p ${2}:${3} --login
EXIT_STATUS="$?"
if [ "${EXIT_STATUS}" == 0 ]; then
  echo -n "$(echo "$1 $2 $3" >> /boot/config/plugins/iscsi-initiator/targets.cfg)"
elif [ "${EXIT_STATUS}" == 15 ]; then
  echo "WARNING: Already connected to target ${1} on ${2}:${3}, not connecting again!"
  exit 1
elif [ "${EXIT_STATUS}" == 21 ]; then
  echo "ERROR: No target with name ${1} found on: ${2}:${3}"
  exit 1
else
  echo "ERROR: iSCSI connection not successful!"
  echo "Error Code: ${EXIT_STATUS}"
  exit 1
fi
}

function remove_target(){
iscsiadm -m node -T ${1} -p ${2}:${3} --logout
sed -i "/$1 $2 $3/d" /boot/config/plugins/iscsi-initiator/targets.cfg
}

function reconnect_single(){
iscsiadm -m node -T ${1} -p ${2}:${3} --logout
sleep 0.5
echo
timeout 5 iscsiadm -m discovery -t sendtargets -p ${2}:${3} > /dev/null 2>&1
iscsiadm -m node -T ${1} -p ${2}:${3} --login
}

$@