#!/bin/bash

function get_initiator_name(){
echo -n "$(cat /boot/config/plugins/iscsi-initiator/initiatorname.cfg | cut -d '=' -f2)"
}

function change_initiator_name(){
echo -n "$(sed -i "/InitiatorName=/c\InitiatorName=${1}" "/boot/config/plugins/iscsi-initiator/initiatorname.cfg")"
echo -n "$(iscsiadm -m node --logout)"
echo -n "$(kill $(pidof iscsid))"
echo -n "$(iscsid --config=/boot/config/plugins/iscsi-initiator/iscsid.conf --initiatorname=/boot/config/plugins/iscsi-initiator/initiatorname.cfg))"
}

function get_active_sessions(){
echo -n "$(iscsiadm --mode session)"
}

function create_target(){
echo -n "$(iscsiadm -m discovery -t sendtargets -p ${2}:${3})"
sleep 0.5
echo -n "$(iscsiadm -m node -T ${1} -p ${2}:${3} --login)"
echo -n "$(echo "$1 $2 $3" >> /boot/config/plugins/iscsi-initiator/targets.cfg)"
}

function remove_target(){
echo -n "$(iscsiadm -m node -T ${1} -p ${2}:${3} --logout)"
echo -n "$(sed -i "/$1 $2 $3/d" /boot/config/plugins/iscsi-initiator/targets.cfg)"
}

$@

