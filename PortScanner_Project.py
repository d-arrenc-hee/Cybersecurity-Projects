#!/usr/bin/python3

# References:
# https://www.youtube.com/watch?v=DoDl-aHC69w
# https://www.youtube.com/watch?v=nYPV1rCVdvs
# https://docs.python.org/3/library/ipaddress.html
# https://www.datacamp.com/tutorial/exception-handling-python?utm_source=google&utm_medium=paid_search&utm_campaignid=19589720821&utm_adgroupid=157156375191&utm_device=c&utm_keyword=&utm_matchtype=&utm_network=g&utm_adpostion=&utm_creative=684592139660&utm_targetid=aud-2274077226600:dsa-2218886984100&utm_loc_interest_ms=&utm_loc_physical_ms=9062544&utm_content=&utm_campaign=230119_1-sea~dsa~tofu_2-b2c_3-row-p1_4-prc_5-na_6-na_7-le_8-pdsh-go_9-nb-e_10-na_11-na&gad_source=1&gclid=Cj0KCQiA7NO7BhDsARIsADg_hIaqHlhIktYxKlpFVMGSDpKqK2QoNZPDOFiNksgsp8c7sYAmHPEqKxUaAnB0EALw_wcB


from concurrent.futures import ThreadPoolExecutor
import socket
import ipaddress
import os
from datetime import datetime
import threading
import re
import subprocess

print_lock = threading.Lock()
log_file = "log_file.txt"
socket.setdefaulttimeout(1) #if no response in 1 seconds, it moves on


# Function for scanning TCP and UDP port 
def scan_port(ip_address, port, protocol):
    try:
        if protocol == "TCP":
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s: # Creating the TCP socket with the command with so that it closes automatically
                result = s.connect_ex((ip_address, port)) # Connect to the inputted IP address with the specified port
                if result == 0:  # Port is open
                    with print_lock:
                        print(f"TCP Port {port}: Open")
                    
                    # Attempt to receive banner
                    try:
                        banner = s.recv(1024)
                        with print_lock:
                            print(f"Banner for TCP Port {port}: {banner.strip()}")
                        log_message(ip_address, port, "TCP", f"Open (Banner: {banner.strip()})")
                    except Exception as e:
                        with print_lock:
                            print(f"Failed to retrieve banner for TCP Port {port}: {e}")
                        log_message(ip_address, port, "TCP", "Open (No Banner)")
                else:
                    log_message(ip_address, port, "TCP", "Closed")
        elif protocol == "UDP":
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.settimeout(0.5)
                # Attempt to send and receive a response from the UDP port
                try:
                    s.sendto(b"Test", (ip_address, port))
                    response, _ = s.recvfrom(1024)
                    with print_lock:
                        print(f"UDP Port {port}: Open (Response: {response})")
                    log_message(ip_address, port, "UDP", "Open (Response: {response})")
                except socket.timeout:
                    log_message(ip_address, port, "UDP", "Closed")
                except Exception as e:
                    log_message(ip_address, port, "UDP", f"Error: {e}")
    except Exception as e:
        with print_lock:
            print(f"No Response {port} ({protocol}): {e}")
            
# Creating a log file 
def log_message(ip_address, port, protocol, status):
    mode = 'a' if os.path.exists(log_file) else 'w'
    with open(log_file, mode) as file:
        file.write(f"{datetime.now()} - IP: {ip_address}, Port: {port}, Protocol: {protocol}, Status: {status}\n")

# Creating a multi-thread to reduce the scan time 
def scan_ports_multithreaded(ip_address, start_port, end_port, max_threads=50):
    with ThreadPoolExecutor(max_threads) as executor:
        for port in range(start_port, end_port + 1):
            executor.submit(scan_port, ip_address, port, "TCP")
            executor.submit(scan_port, ip_address, port, "UDP")

# Creating a multi-thread to reduce the ping time 
def ping_ip_multithreaded(start_ip, end_ip, max_threads=50):
    
    # Pings a range of IP addresses using multithreading.
    with ThreadPoolExecutor(max_threads) as executor:
        # Generate all IPs in the range
        ip_range = [ipaddress.IPv4Address(ip) for ip in range(int(start_ip), int(end_ip) + 1)]
        # Submit the `ping_ip` function for each IP
        executor.map(ping_ip, ip_range)

# Aquiring the IP address range to scan 
def get_ip_range():
    while True:
        try:
            start_ip = input("Please enter the starting IP address: ")
            end_ip = input("Please enter the ending IP address: ")

            # Validate IPs
            start = ipaddress.IPv4Address(start_ip)
            end = ipaddress.IPv4Address(end_ip)
            
			# Ensuring the IP range given is valid
            if start > end:
                print("The starting IP address cannot be greater than the ending IP address. Please try again.")
            else:
                return start, end
        except ipaddress.AddressValueError:
            print("Invalid IP address. Please try again.")

def ping_ip(ip):
	# Ping the IP address
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "1", str(ip)],  # "-c 1" for one ping, "-W 1" for timeout
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        # Analysing the feedback from the ping and determine if the IP address is up
        if result.returncode == 0:
            print(f"{ip} is reachable.")
            
            mode = 'a' if os.path.exists(log_file) else 'w'
            with open(log_file, mode) as file:
                file.write(f"{datetime.now()} - (ping) IP address: {ip} is reachable\n")
        else:
            print(f"{ip} is unreachable.")
            
            mode = 'a' if os.path.exists(log_file) else 'w'
            with open(log_file, mode) as file:
                file.write(f"{datetime.now()} - (ping) IP address: {ip} is unreachable\n")
    except Exception as e:
        print(f"An error occurred while pinging {ip}: {e}")
        
# Creating a menu for user to select various option to scan, ping or exit
def menu():
    while True:
        choice = input('Select an option:\n1. Scan IP address or Host name\n2. Ping IP address\n3. Exit\nChoice: ')
        if choice == '1':
            ip_address_host = input('Enter the IP address: ')
            ip_address = socket.gethostbyname(ip_address_host)
            start_port = int(input('Enter starting port: '))
            end_port = int(input('Enter ending port: '))
            max_threads = int(input('Enter max threads (default 50): ') or 50)
            print(f"Scanning IP: {ip_address} (Ports {start_port}-{end_port}) with {max_threads} threads...")
            scan_ports_multithreaded(ip_address, start_port, end_port, max_threads)
        elif choice == '2':
            start_ip, end_ip = get_ip_range()
            max_threads = int(input("Enter max threads for pinging (default 50): ") or 50)

            print(f"Pinging all IPs from {start_ip} to {end_ip} with {max_threads} threads...\n")
            ping_ip_multithreaded(start_ip, end_ip, max_threads)
        elif choice == '3':
            break
        else:
            print('Invalid choice. Try again.')


if __name__ == "__main__": # Checks if the current script is run as the main program, or if it's being imported into another program
    menu()

