#!/bin/bash
# This script performs a DNS lookup and returns various records for a given domain.
# Make sure a domain is provided as an argument
# https://github.com/CaptainWilder/
if [ -z "$1" ]; then
          echo "Usage: dns_lookup.sh DOMAIN"
            exit 1
fi

# Perform an A record lookup and get the IP
ip=$(dig +short A "$1")

# Check if the IP is in the 38.97.16.0/24 or 38.67.13.0/24 networks
if [[ "$ip" =~ ^38\.97\.16\.[0-9]{1,3}$ || "$ip" =~ ^38\.67\.13\.[0-9]{1,3}$ ]]; then
          org="TRINSIC"
  else
            # Perform a whois lookup on the IP and extract the Organization field
              org=$(whois "$ip" | grep 'Organization:' | awk '{print $2}')
fi

# Perform an MX record lookup
mx=$(dig +short MX "$1")

# Perform an NS record lookup
ns=$(dig +short NS "$1")

# Perform a CNAME record lookup
cname=$(dig +short CNAME "www.$1")

# Perform a TXT record lookup
txt=$(dig +short TXT "$1" | grep spf)

# Perform a WHOIS search and extract the registrar name
registrar=$(whois "$1" | grep -m 1 'Registrar:')

# Output the results
echo "A record: $ip"
echo "WebHost: $org"
echo "WHOIS $registrar"
echo " CNAME record: $cname"
echo "MX record: $mx"
echo "NS records: $ns"
echo "SPF: $txt"


#ports=( 21 22 23 25 53 80 110 123 143 161 389 443 445 465 993 587 995 3306 )
# Iterate through the array of port numbers
#for port in "${ports[@]}"
#do
          # Use nc to check if the port is open on the target host
#           if nc -z "$1" "$port"
#                     then
#                                 echo "Port $port is open on $1"
#                                   fi
#                           done
