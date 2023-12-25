#!/bin/bash
#######################
###Wilder Army Knife###
######DNS Tools########
#######################


#for debug, uncomment echos 

#Prereq Check
#echo "Checking for prereqs..." #Enable Debug
install_whois() {
  if which whois >/dev/null; then
    echo "Loading..."
  else
    echo "whois not found. Installing..."
    if [[ ! -z $(which yum) ]]; then
      sudo yum install whois -y
    elif [[ ! -z $(which apt) ]]; then
      sudo apt-get install whois -y
    else
      #echo "Neither yum nor apt is available. Cannot install whois."
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


#debug 
#echo "Loading..."

#DNS Lookups
#A record lookup and get the IP
ip=$(dig +short A "$DOMAIN")
ip_org=$(echo "$ip" | head -n1 )

#Whois lookup on the IP and extract the Organization field
org=$(whois "$ip_org" | grep 'OrgName:' | awk '{$1=""; print substr($0,2)}')

#MX record lookup
mx=$(dig +short MX "$DOMAIN")

#NS record lookup
ns=$(dig +short NS "$DOMAIN")

#CNAME record lookup
cname=$(dig +short CNAME "www.$DOMAIN")

#TXT record lookup
txt=$(dig +short TXT "$DOMAIN" | grep spf)

#WHOIS search and extract the registrar name
registrar=$(whois "$DOMAIN" | grep -m 1 'Registrar:' | awk '{$1=""; print substr($0,2)}')


#debug
#echo "Got dns..."
#echo "Loading SSL..."

#HTTPS Check
if ! curl --output /dev/null --silent --head --fail --connect-timeout 5 "https://$DOMAIN"; then
  echo "HTTPS not enabled or the domain is not reachable."
  ssl_expiry="no SSL"
  ssl_issuer="no SSL"
else
  ssl_output=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates -issuer)
  ssl_expiry=$(echo "$ssl_output" | grep 'notAfter' | awk -F= '{print $2}')
  ssl_issuer=$(echo "$ssl_output" | grep 'issuer=' | sed -n 's/.*O = \(.*\), CN = .*/\1/p')
fi


#Output
echo "----------------------- DNS & SSL Details -----------------------"
echo -e "\033[31mWebHost: \033[0m\n$org" #WebHost
echo -e "\033[31mRegistrar: \033[0m\n$registrar" #Registrar
echo -e "\033[31mSSL Expiration: \033[0m\n$ssl_expiry" #SSL Expiration 
echo -e "\033[31mSSL Issuer: \033[0m\n$ssl_issuer" #SSL Issuer 
echo -e "\033[31mIP: \033[0m\n$ip" #IP
echo -e "\033[31mNS records: \033[0m\n$ns" #NS
echo -e "\033[31mCNAME record: \033[0m\n$cname" #CNAME
echo -e "\033[31mMX record: \033[0m\n$mx" #MX
echo -e "\033[31mSPF: \033[0m\n$txt" #SPF
echo "---------------------------------------------------------------"
