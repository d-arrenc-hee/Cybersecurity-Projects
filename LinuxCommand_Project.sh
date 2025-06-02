#!/bin/bash

#external ip address
external_ip=$(curl -s ifconfig.io | awk -F. '{print ""$1":"$2":XX:XX"}')

#internal ip address
internal_ip=$(ifconfig | grep inet | awk '{print $2}' | head -1)

#MAC address of the machine .
mac_addr=$(ifconfig | grep ether | awk '{print $2}' | awk -F: '{print "XX:XX:XX:"$4":"$5":"$6""}') 

#Top 5 processes CPU usage 
top_processes=$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6)

#Memory Usage, Free and Used
memory_usage=$(free -h | grep Mem | awk '{print $3 "/" $2}')

#Active System Services and Status 
active_services=$(systemctl list-units --type=service --state=running --no-pager | awk '{print $1,$3}' | column -t | head -n 20)

#Top 10 Files from /home Directory
file_sizes=$(du -ah /home | sort -rh | head -n 10)

read -p "Enter the secret code (hint: CFCI): " input 

code="CFCI"

if [ "$input" == "$code" ]; then

    #Display information
    echo "============================================="
    echo "             System Information              "
    echo "============================================="

    echo "1. External IP Address:   $external_ip"
    echo "2. Internal IP Address:   $internal_ip"
    echo "3. MAC Address:           $mac_addr"
    echo "4. Top 5 Processes CPU Usage:"
    echo "$top_processes"
    echo "5. Memory Usage:          $memory_usage"
    echo "6. Active Services:       $active_services"
    echo ""
    echo "7. Top 10 Files in /home Directory:"
    echo "$file_sizes"

else 
    echo "The secret code is the hint" 

fi 




