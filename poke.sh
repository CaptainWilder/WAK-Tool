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
    echo ""
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


#Function to format multiline output
format_output() {
    local label=$1
    local text=$2
    local first_line=true

    # Read each line of the variable
    while IFS= read -r line; do
        if [ "$first_line" = true ] ; then
            printf "%-25s %s\n" "$label" "$line"
            first_line=false
        else
            printf "%-25s %s\n" "" "$line"
        fi
    done <<< "$text"
}

# Output
echo "----------------------- DNS & SSL Details -----------------------"
format_output "IP:" "$ip"
format_output "WebHost:" "$org"
format_output "Registrar:" "$registrar"
format_output "CNAME record:" "$cname"
format_output "MX record:" "$mx"
format_output "NS records:" "$ns"
format_output "SPF:" "$txt"
format_output "SSL Certificate Expiration:" "$ssl_expiry"
format_output "SSL Certificate Issuer:" "$ssl_issuer"
echo "----------------------------------------------------------------"
