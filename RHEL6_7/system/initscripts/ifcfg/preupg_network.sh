#!/bin/bash
. /usr/share/preupgrade/common.sh

orig_name_base="eth"
new_name_base="net"
conf_dir='/etc/sysconfig/network-scripts'
temp_conf_dir="$VALUE_TMP_PREUPGRADE/dirtyconf/etc/sysconfig/network-configuration_fixed/"
preupg_dir="$VALUE_TMP_PREUPGRADE/preupgrade-scripts"
preupg_script="$preupg_dir/rename_network.sh"
udev_command='/sbin/udevadm info -a  -p'
dev_path='/sys/class/net'
index=0

declare -a netX_indices
declare -a ethX_ifaces

for net_index in $(ip a | awk -F': ' '/^[[:digit:]]+: net[[:digit:]]+/ {print $2  }' | sed -e "s/net//g"| sort )
do
    netX_indices+=( "$net_index" )
done

for eth_iface in $(ip a | awk -F': ' '/^[[:digit:]]+: eth[[:digit:]]+/ {print $2  }')
do
    ethX_ifaces+=( "$eth_iface" )
done

if [ ${#netX_indices[@]} -ne 0 ] && [ ${#ethX_ifaces[@]} -gt 1 ];then
   log_info "There are pre-existing netX interfaces on the system as well as multiple ethX interfaces. The index of renamed ethX interfaces will be changed in order to prevent the naming conflicts."
fi

cat /dev/null > udev_temp 
cat /dev/null > "$preupg_script"

echo '#!/bin/bash' >> "$preupg_script"
echo 'service network stop'  >> "$preupg_script"

echo '#!/bin/bash
echo "Invalid network configuration detected, stopping upgrade" >&2
exit 1' > invalid_config_check.sh

chmod u+x invalid_config_check.sh

if ls "$dev_path" | grep -q -E "rename[0-9]+$";then
    cp -p invalid_config_check.sh "$preupg_dir"
    exit 1
fi

if grep -q "^MACADDR=" "$conf_dir"/ifcfg-*;then
    cp -p invalid_config_check.sh "$preupg_dir"
    exit 2
fi

if ! [ -e "$temp_conf_dir" ];then
    mkdir -p "$temp_conf_dir"
fi

for orig_full_name in ${ethX_ifaces[@]}
do
    orig_conf_file="${conf_dir}/ifcfg-${orig_full_name}"
    mac=$(/sbin/ethtool -P $orig_full_name | awk '{ print $3}')
    mac_rule=$(echo "ATTR{address}==\"$mac\"")
    dev_type_rule=$($udev_command "${dev_path}/${orig_full_name}" | egrep "ATTR\{type\}")
    index=$(echo $orig_full_name |sed -e "s/^$orig_name_base//g")

    for net_index in ${netX_indices[@]}
    do
        while [ $index -eq $net_index ]
        do
            index=$(expr $index + 1)
        done
    done
    netX_indices=(${netX_indices[@]} $index )
    new_full_name="${new_name_base}$index"
    log_info "On the target system, the $orig_full_name interface will become $new_full_name."

    if [ -f "$orig_conf_file" ];then
        if [ -n "$new_full_name" ];then
           new_conf_file="${temp_conf_dir}/ifcfg-${new_full_name}"
           cp -p "$orig_conf_file" "$new_conf_file"
           sed -i "s/^HWADDR=.*/HWADDR=$mac/g" "$new_conf_file"
           sed -r -i "s/^NAME=.*|^DEVICE=.*/DEVICE=$new_full_name/g" "$new_conf_file"
           echo "ip link set $orig_full_name name $new_full_name" >> "$preupg_script"
           echo "cp -p $new_conf_file $conf_dir" >> "$preupg_script"
           echo "rm -f $orig_conf_file" >> "$preupg_script"
        fi
    fi

    echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", $mac_rule, $dev_type_rule, NAME=\"$new_full_name\"\n" >> udev_temp

done


mv udev_temp "$temp_conf_dir"
echo "cp -p $temp_conf_dir/udev_temp /etc/udev/rules.d/70-persistent-net.rules" >> "$preupg_script"
echo 'service network start'  >> "$preupg_script"
chmod u+x "$preupg_script"


echo "If there are multiple interfaces with \"$orig_name_base\" prefix on the system, they will be renamed to use \"$new_name_base\" prefix by $preupg_script script executed by redhat-upgrade-tool before the upgrade.You can edit the $preupg_script as well as the associated udev rules for a custom configuration
      This process includes the restart of the network" >> solution.txt

