#!/bin/bash 

#Check if the following application is installed. If not, install the application: 
# 1. nmap
# 2. geoip-bin 
# 3. ssh
# 4. sshpass
# 5. whois
# 6. Tor
# 7. Nipe

#0. Update the database before installing the services 
sudo apt -y update &>/dev/null

#1. To check if nmap is installed and send the output to /dev/null
dpkg -s nmap 1>/dev/null
# Check the exit command. If the program is not installed, return (1) 
# Install the program if not installed. Inform the user if the program is already installed
if [ $? == 1 ]
then 
    echo "[#] nmap is currently installing .."
    sudo apt-get -y install nmap &>/dev/null
    echo "[#] nmap is installed"
else 
    echo "[#] nmap is already installed"
fi 

#2. To check if geoip-bin is installed

dpkg -s geoip-bin &>/dev/null

if [ $? == 1 ]
then 
    echo "[#] geoip-bin is currently installing .."
    sudo apt -y install geoip-bin &>/dev/null
    echo "[#] geoip-bin is installed "
else 
    echo "[#] geoip-bin is already installed"
fi 

#3. To check if SSH is installed

dpkg -s openssh-client &>/dev/null

if [ $? == 1 ]
then 
    echo "[#] openssh-client is currently installing .."
    sudo apt-get -y install openssh-client &>/dev/null
    echo "[#] openssh-client is installed "
else 
    echo "[#] SSH is already installed"
fi 

#4. To check if sshpass is installed 

dpkg -s sshpass &>/dev/null

if [ $? == 1 ]
then 
    echo "[#] sshpass is currently installing .."
    sudo apt-get -y install sshpass &>/dev/null
    echo "[#] sshpass is installed "
else 
    echo "[#] SSHpass is already installed"
fi 

#5. To check if whois is installed

dpkg -s whois 1>/dev/null

if [ $? == 1 ]
then 
    echo "[#] whois is currently installing .."
    sudo apt-get -y install whois &>/dev/null
    echo "[#] whois is installed "
else 
    echo "[#] whois is already installed"
fi 

#6. To check if tor is installed

dpkg -s tor &>/dev/null

if [ $? == 1 ]
then 
    echo "[#] tor is currently installing .."
    sudo apt-get -y install tor &>/dev/null
    echo "[#] tor is installed "
else 
    echo "[#] tor is already installed"
fi 

# nipe_installer
# 1. Get the nipe directory from github 
# 2. Find if nipe.pl exists in the nipe directory
# 3. If found, enter intp the nipe folder and install cpanminus
function nipe_installer()
{

git clone https://github.com/htrgouvea/nipe
nipedir=$(find / -type f -name "nipe.pl" 2>/dev/null | sed 's|/nipe.pl||')
if [ ! -z $nipedir ]
then 
    cd $nipedir
    sudo apt-get -y install cpanminus 
    cpanm --installdeps .
    sudo cpan install Switch JSON LWP::UserAgent Config::Simple
    sudo perl nipe.pl install
fi

}

#7. To check if nipe is installed 

nipepldir=$(find / -name "nipe.pl" 2>/dev/null)

if [ ! -z "$nipepldir" ]
then 
    echo "[#] Nipe exist on this machine"
    dpkg -s cpanminus
    if [ $? == 1 ]
    then 
        echo "[#] cpanminus is installing.."
        sudo apt-get -y install cpanminus
        echo "[#] cpanminus is installed "
    else 
        echo "[#] cpanminus is already installed"
    fi
else 
    nipe_installer
fi

# Connect through NIPE
# 1. Check connection status 

function nipe_connection()
{
    # finding the file of /nipe/nipe.pl and removing the file nipe.pl to navigate into the directory since
    # there are more than one file in the /nipe folder
    nipedir=$(find / -type f -name "nipe.pl" 2>/dev/null | sed 's|/nipe.pl||')
    if [ -z "$nipedir" ]; then
        echo "[#] Nipe.pl not found. Please install Nipe or verify its location."
        return 1
    fi
    # Restart the tor.service to prevent any connection error 
    sudo systemctl restart tor.service
    # Navigate into the nipe directory folder and start the start the perl-based engine to anonymize the web traffic
    cd $nipedir
    sudo perl nipe.pl start
    nipe_status=$(sudo perl nipe.pl status | grep -o "false")
    nipe_status_2=$(sudo perl nipe.pl status | grep -o "ERROR")

    # If the nipe service is not annonymized, restart the engine until the user is annonymous
    while [[ "$nipe_status" == "false" || "$nipe_status_2" == "ERROR" ]]
    do 
        sudo perl nipe.pl restart
    done

    # Display the spoofed IP address and country after being annoymous
    spoofip=$(curl -s ifconfig.io)
    spoof_country=$(geoiplookup $spoofip | awk '{print $4,$5}')

    echo "[*] Spoofed IP address: $spoofip"
    echo "[*] Spoofed country: $spoof_country"
    echo ""
    echo "[*] You are anonymous .. Connecting to the remote Server."
}

nipe_connection

# Function to validate domain or IP address
function validate_input() 
{
input=$1
# Regex for IPv4 address
ipv4_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
# Regex for domain name
domain_regex="^(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})$"

    if [[ $input =~ $ipv4_regex ]]
    then
        # Check if each octet of IPv4 is within 0-255
        # If the octet is within the range, return True (0), else False (1)
        IFS='.' read -ra octets <<< "$input"
        for octet in "${octets[@]}"
        do
            if ((octet < 0 || octet > 255))
            then
                return 1
            fi
        done
        return 0
    elif [[ $input =~ $domain_regex ]]
    then
        return 0
    fi
    return 1
}

# Creating a log file on kali 
log_file=$(find / -type f -name "scan.log" 2>/dev/null)
if [[ -z "$log_file" ]]
then
    sudo touch /var/log/scan.log
fi


# Prompt user for input for the domain/IP address for scanning and the remote server to connect to.
while true
do
    read -p "[?] Enter a domain or IP address: " user_input
    read -p "[?] Enter remote server IP address (ubuntu): " ubuntu_remoteip

# Check if the input is valid. If valid, conenct to the SSH server while sending the output to /dev/null.
# if the input is not valid, prompt the user to input the domain again  
# While connected to the remote server, scan the domain using nmap and whois and save the file in the /home/tc folder
    if validate_input "$user_input" && validate_input "$ubuntu_remoteip"
    then
        sshpass -p tc ssh -t -o StrictHostKeyChecking=no tc@$ubuntu_remoteip 1>/dev/null << EOF 
        scan_file="/home/tc/${user_input}_scan.on"
        nmap $user_input -sV -oN "\$scan_file" 1>/dev/null
        whois $user_input >> "\$scan_file"

        echo "[*] Scan completed for $user_input. Results saved to \$scan_file."
EOF

# Download the file that contains the scan to the local folder ~/Desktop
# Create the log file and save the details of the the domain scanned with the services and date and time. 
        sshpass -p tc scp -o StrictHostKeyChecking=no tc@$ubuntu_remoteip:/home/tc/${user_input}_scan.on ~/Desktop
        echo "[*] Scan results downloaded to local machine: ${user_input}_scan.on"
        echo "$(date) - [*] Nmap and Whois data collected for: $user_input" | sudo tee -a /var/log/scan.log > dev/null
        break
    else
        echo "[*] Invalid input. Please enter a valid domain or IP address."
    fi
done



