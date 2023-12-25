#!/bin/bash
#######################
###Wilder Army Knife###
######DNS Tools########
#######################

#Prereq Check
install_whois() {
  if which whois >/dev/null; then
    echo "whois is already installed."
  else
    echo "whois not found. Installing..."
    if [[ ! -z $(which yum) ]]; then
      sudo yum install whois -y
    elif [[ ! -z $(which apt) ]]; then
      sudo apt-get install whois -y
    else
      echo "Neither yum nor apt is available. Cannot install whois."
      exit 1
    fi
  fi
}

#Install Prereq
install_whois

#Get Input/Argument
if [ -z "$1" ]; then
  echo "Usage: poke.sh DOMAIN"
  exit 1
fi

DOMAIN="$1"

#A record lookup and get the IP
ip=$(dig +short A "$DOMAIN")
ip_org=$(echo "$ip" | head -n1 )

#Whois lookup on the IP and extract the Organization field
org=$(whois "$ip_org" | grep 'Organization:' | awk '{print $2}')

#MX record lookup
mx=$(dig +short MX "$DOMAIN")

#NS record lookup
ns=$(dig +short NS "$DOMAIN")

#CNAME record lookup
cname=$(dig +short CNAME "www.$DOMAIN")

#TXT record lookup
txt=$(dig +short TXT "$DOMAIN" | grep spf)

#WHOIS search and extract the registrar name
registrar=$(whois "$DOMAIN" | grep -m 1 'Registrar:' | awk '{$1=$1;print}')

#SSL certificate expiration and issuer details
echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates -issuer > ssl_details.txt
ssl_dates=$(grep -e 'notBefore' -e 'notAfter' ssl_details.txt)
ssl_issuer=$(grep 'issuer' ssl_details.txt)

#Output
echo "IP: $ip"
echo "WebHost: $org"
echo "$registrar"
echo "CNAME record: $cname"
echo "MX record: $mx"
echo "NS records: $ns"
echo "SPF: $txt"
echo "SSL Certificate Dates: $ssl_dates"
echo "SSL Certificate Issuer: $ssl_issuer"

#Clean up temporary file
rm ssl_details.txt
