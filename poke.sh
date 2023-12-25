#!/bin/bash
#######################
###Wilder Army Knife###
######DNS Tools########
#######################


#Get Input/Argument
if [ -z "$1" ]; then
          echo "Usage: poke.sh DOMAIN"
            exit 1
fi

#A record lookup and get the IP
ip=$(dig +short A "$1")
ip_org=$(echo "$ip" | head -n1 )

#Whois lookup on the IP and extract the Organization field
org=$(whois "$ip_org" | grep 'Organization:' | awk '{print $2}')

#MX record lookup
mx=$(dig +short MX "$1")

#NS record lookup
ns=$(dig +short NS "$1")

#CNAME record lookup
cname=$(dig +short CNAME "www.$1")

#TXT record lookup
txt=$(dig +short TXT "$1" | grep spf)

#WHOIS search and extract the registrar name
registrar=$(whois "$1" | grep -m 1 'Registrar:' | awk '{$1=$1;print}')

#Output
echo "IP: $ip"
echo "WebHost: $org"
echo "$registrar"
echo "CNAME record: $cname"
echo "MX record: $mx"
echo "NS records: $ns"
echo "SPF: $txt"
