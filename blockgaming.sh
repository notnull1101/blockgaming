#!/usr/bin/env bash
# Create Iptables Chain 
# iptables -L -n blockgaming
# Add Chain to iptables rules 
# iptables -I INPUT 2 -j blockgaming
#
# Add Cron job 
# Block Gaming
# */6 *   * * * root /root/bin/blockgaming.sh &> /dev/null

# Block Internet Connection
function block_traffic(){

    # Get Device list 
    get_macaddress

    # Only Block Traffic from 20:00 >= 08:00 i.e From 8pm to 8am 
    # else allow traffic
    if [[ $get_hour -ge $block_hours ]] || [[ $get_hour -eq 00 ]] || [[ $get_hour -le $allowed_hours ]]; then
        # Check if temp files exist 
        # if temp file exist do not do anything 
        # Else insert iptables rules and create the $temp_file
        if [[ ! -f $temp_file ]]; then
            
            # loop through $block_devices array and append to iptables 
            for i in ${!block_devices[@]} ; do

                # MAC Address 
                mac_address=${block_devices[$i]}
                
                # IP Tables Rules
                iptables_rule="-I blockgaming -m mac --mac-source ${mac_address} -j DROP"

                # Block Traffic
                echo  $iptables_rule


            done

            # Create Temp File
            touch $temp_file
        fi
    

    else
        # Allow Traffic
        allow_traffic
    fi
}


# Allow Internet Traffic
function allow_traffic(){
    # Reove Temp File 
    rm -rf $temp_file

    # Flush blockgaming Chain
    # iptables -F blockgaming
    echo "Flushing Tables"
}

# Get Mac Address
function get_macaddress(){

    # Check if $device_list exist 
    # if it does not exist exit script
    if [[ -f $device_list ]]; then
        # List Devices
        while read line; do 
            
            # Only Parse Line that do not have comments on them
            if [[ ! $line =~ ^# ]]; then
                
                # Explode Line 
                IFS="|" read -a device <<< "$line"

                # Macc Address 
                local mac_address=${device[0]}

                # Device Name 
                local device_name=${device[1]}

                # Append Mac Address to block_devices arrat 
                block_devices+=( $mac_address )

            fi

        done < $device_list
    else 
        echo "$device_list missing "
        exit
    fi

}


# Block Devices MAC ADDRESS Array
declare -a block_devices

# Device List
device_list="devices.list"

# Temp File
temp_file="/tmp/blockgaming"

# Get Time
get_hour=$( date +%-H )
 
# Get Dat if the week 
# day of week (1..7); 1 is Monday
# 1 monday
# 2 tuesday
# 3 wendsday
# 4 thursday
# 5 friday
# 6 saturday
# 7 sunday
get_day=$( date +%u )

# Military time 20:00 8PM
# Blackout Hours 
block_hours=20

# Military Time 08:00 8AM
# Allowed Time
allowed_hours=8

# Only Block Monday - Thursday, and Sunday
case $get_day in
    [12347] )
        # Call block traffic
        block_traffic
        ;;
    [56] )
        # Call Allow Traffic
        allow_traffic
        ;;
esac
